import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../crypto/cryptography.dart';
import '../crypto/util.dart';
import '../entity/dht/base.dart';
import '../entity/dht/myself.dart';
import '../service/dht/peerclient.dart';
import '../tool/util.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:cryptography/cryptography.dart';

import 'message.dart';

const int CompressLimit = 2048;

class SecurityParams {
  String? TransportPayload;
  String? PayloadSignature;
  String? PreviousPublicKeyPayloadSignature;
  bool NeedCompress = true;
  bool NeedEncrypt = true;
  late String PayloadKey;
  String? TargetPeerId;
  late String SrcPeerId;
  String? PayloadHash;
}

/// 对任意结构的负载进行压缩，签名，加密处理
class SecurityPayload {
  SecurityPayload();

  /// 加密参数必须有是否压缩，是否加密，目标peerId
  /// 返回参数包括结果负载，是否压缩，是否加密，加密键值，签名
  /// @param payload
  /// @param securityParams
  static Future<SecurityParams> encrypt(
      dynamic payload, SecurityParams securityParams) async {
    SecurityParams result = SecurityParams();
    var transportPayload = JsonUtil.toJsonString(payload);
    // 原始字符串转换成utf-8数组
    List<int> data = utf8.encode(transportPayload);

    // 消息的数据部分转换成字符串，签名，加密，压缩，base64
    var privateKey = myself.privateKey;
    if (privateKey == null) {
      throw 'NullPrivateKey';
    }
    result.NeedEncrypt = securityParams.NeedEncrypt;
    result.NeedCompress = securityParams.NeedCompress;
    // 1.设置签名（本地保存前加密不签名）
    var targetPeerId = securityParams.TargetPeerId;
    var myselfPeer = myself.myselfPeer;
    var peerId = myselfPeer?.peerId;
    if (securityParams.NeedEncrypt &&
        targetPeerId != null &&
        myselfPeer != null &&
        peerId != null &&
        !targetPeerId.contains(peerId)) {
      var payloadSignature = await cryptoGraphy.sign(data, privateKey);
      result.PayloadSignature = CryptoUtil.uint8ListToStr(payloadSignature);
      if (myself.expiredKeys.isNotEmpty) {
        var previousPublicKeyPayloadSignature =
            await cryptoGraphy.sign(data, myself.expiredKeys[0]);
        result.PreviousPublicKeyPayloadSignature =
            CryptoUtil.uint8ListToStr(previousPublicKeyPayloadSignature);
      }
    }

    // 本地保存NeedCompress为true即压缩，ChainMessage压缩还需判断transportPayload.length
    if (securityParams.NeedCompress &&
        (targetPeerId == null ||
            (targetPeerId == null &&
                transportPayload.length > CompressLimit))) {
      //2. 压缩数据
      data = CryptoUtil.compress(data);
    } else {
      result.NeedCompress = false;
    }
    if (securityParams.NeedEncrypt == true) {
      //3. 数据加密，base64
      var targetPublicKey;
      if (targetPeerId != null &&
          myselfPeer != null &&
          peerId != null &&
          !targetPeerId.contains(peerId)) {
        targetPublicKey =
            await PeerClientService.instance.getPublic(targetPeerId);
      } else {
        // 本地保存前加密
        targetPublicKey = myself.publicKey;
      }
      if (targetPublicKey == null) {
        if (kDebugMode) {
          print("TargetPublicKey is null, will not be encrypted!");
        }
        result.NeedEncrypt = false;
      }

      // 目标公钥不为空时加密数据
      if (targetPublicKey) {
        var secretKey = null;
        if (securityParams.PayloadKey == null) {
          secretKey = await cryptoGraphy.getRandomAsciiString();
        } else {
          secretKey = await cryptoGraphy.eccDecrypt(
              securityParams.PayloadKey.codeUnits,
              localKeyPair: privateKey);
        }
        data = await cryptoGraphy.aesEncrypt(data, secretKey);
        // 对对称密钥进行公钥加密
        var encryptedKey = await cryptoGraphy.eccEncrypt(secretKey,
            remotePublicKey: targetPublicKey);
        result.PayloadKey = CryptoUtil.uint8ListToStr(encryptedKey);
      } else {
        result.PayloadKey = '';
      }
    }
    // 无论是否经过压缩和加密，进行based64处理
    result.TransportPayload = CryptoUtil.encodeBase64(data);
    // 设置数据的hash，base64
    var payloadHash = await cryptoGraphy.hash(data);
    var payloadHashBase64 = CryptoUtil.encodeBase64(payloadHash);
    result.PayloadHash = payloadHashBase64;

    return result;
  }

  /// 加密参数必须有是否压缩，是否加密，源peerId，目标peerId，加密键值，签名
  /// 返回负载
  /// @param payload
  /// @param securityParams
  static Future<dynamic> decrypt(
      dynamic transportPayload, SecurityParams securityParams) async {
    var targetPeerId = securityParams.TargetPeerId;
    var myselfPeer = myself.myselfPeer;
    // 本地保存前加密targetPeerId可为空
    if (targetPeerId == null ||
        (myselfPeer != null && targetPeerId == myselfPeer.peerId)) {
      // 消息的数据部分，base64
      List<int> data = CryptoUtil.decodeBase64(transportPayload);
      var needEncrypt = securityParams.NeedEncrypt;
      if (needEncrypt == true) {
        // 1.对对称密钥进行私钥解密
        var payloadKey = securityParams.PayloadKey;
        // 消息的数据部分，数据加密过，解密
        if (payloadKey != null) {
          var privateKey = myself.privateKey;
          if (privateKey == null) {
            throw 'NullPrivateKey';
          }
          var payloadKeyData = null;
          try {
            payloadKeyData = await cryptoGraphy.eccDecrypt(
                CryptoUtil.strToUint8List(payloadKey),
                localKeyPair: privateKey);
          } catch (e) {
            print(e);
          }
          var i = 0;
          while (!payloadKeyData && i < myself.expiredKeys.length) {
            try {
              payloadKeyData = await cryptoGraphy.eccDecrypt(
                  CryptoUtil.strToUint8List(payloadKey),
                  localKeyPair: myself.expiredKeys[i]);
            } catch (e) {
              print(e);
            } finally {
              i++;
            }
          }
          if (!payloadKeyData) {
            throw 'EccDecryptFailed';
          }
          // 数据解密
          data = await cryptoGraphy.aesDecrypt(data, payloadKeyData);
        }
      }

      var needCompress = securityParams.NeedCompress;
      if (needCompress == true) {
        // 2. 解压缩
        data = CryptoUtil.uncompress(data);
      }
      //3. 消息的数据部分，验证签名
      var peerId = myselfPeer?.peerId;
      if (needEncrypt == true) {
        var payloadSignature = securityParams.PayloadSignature;
        if (payloadSignature != null) {
          var srcPublicKey = null;
          var srcPeerId = securityParams.SrcPeerId;
          if (srcPeerId != null &&
              peerId != null &&
              (myselfPeer != null && !srcPeerId.contains(peerId))) {
            srcPublicKey =
                await PeerClientService.instance.getPublic(srcPeerId);
          } else {
            throw 'NullSrcPeerId';
            // 本地保存前加密如果签名，验签需尝试所有expiredPublicKey
            //srcPublicKey = myself.publicKey
          }
          if (!srcPublicKey) {
            throw 'NullSrcPublicKey';
          }
          var pass = await cryptoGraphy.verify(data, payloadSignature.codeUnits,
              publicKey: srcPublicKey);
          if (!pass) {
            var previousPublicKeyPayloadSignature =
                securityParams.PreviousPublicKeyPayloadSignature;
            if (previousPublicKeyPayloadSignature != null) {
              pass = await cryptoGraphy.verify(
                  data, previousPublicKeyPayloadSignature.codeUnits,
                  publicKey: srcPublicKey);
            }
            if (!pass && securityParams.SrcPeerId != null) {
              var peerClients = [
                peerClientService
                    .getPeerClientFromCache(securityParams.SrcPeerId)
              ];
              if (peerClients != null && peerClients.isNotEmpty) {
                srcPublicKey = await PeerClientService.instance
                    .getPublic(securityParams.SrcPeerId);
                if (!srcPublicKey) {
                  throw 'NullSrcPublicKey';
                }
                pass = await cryptoGraphy.verify(
                    data, payloadSignature.codeUnits,
                    base64PublicKey: srcPublicKey);
                if (!pass) {
                  print("PayloadVerifyFailure");
                  //throw new Error("PayloadVerifyFailure")
                }
              } else {
                print("PeerClientNotExists");
              }
            }
          }
        }
      }
      var str = CryptoUtil.uint8ListToStr(data);
      var payload = MessageSerializer.unmarshal(data);

      return payload;
    }

    return null;
  }
}
