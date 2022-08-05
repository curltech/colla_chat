import 'package:cryptography/cryptography.dart';

import '../../crypto/cryptography.dart';
import '../../crypto/util.dart';
import '../../entity/dht/myself.dart';
import '../../entity/p2p/security_context.dart';
import '../../provider/app_data_provider.dart';
import '../../service/dht/peerclient.dart';
import '../../tool/util.dart';

/// 对任意结构的负载进行压缩，签名，加密处理
class SecurityContextService {
  SecurityContextService();

  /// 加密参数必须有是否压缩，是否加密，目标peerId
  /// 返回参数包括结果负载，是否压缩，是否加密，加密键值，签名
  /// @param payload
  /// @param securityParams
  static Future<SecurityContext> encrypt(
      List<int> payload, SecurityContext securityContext) async {
    List<int> data = payload;
    SecurityContext result = SecurityContext();
    // 消息的数据部分转换成字符串，签名，加密，压缩，base64
    var myselfPrivateKey = myself.privateKey;
    if (myselfPrivateKey == null) {
      throw 'NullMyselfPrivateKey';
    }
    result.needEncrypt = securityContext.needEncrypt;
    result.needCompress = securityContext.needCompress;
    result.needSign = securityContext.needSign;
    // 1.设置签名（本地保存前加密不签名），只有在加密的情况下才设置签名
    var targetPeerId = securityContext.targetPeerId;
    var peerId = myself.peerId;
    if (securityContext.needSign &&
        targetPeerId != null &&
        peerId != null &&
        targetPeerId != peerId) {
      /// 签名，并且用上一次过期的私钥也签名
      var payloadSignature = await cryptoGraphy.sign(data, myselfPrivateKey);
      result.payloadSignature = CryptoUtil.encodeBase64(payloadSignature);
      if (myself.expiredKeys.isNotEmpty) {
        var previousPublicKeyPayloadSignature =
            await cryptoGraphy.sign(data, myself.expiredKeys[0]);
        result.previousPublicKeyPayloadSignature =
            CryptoUtil.encodeBase64(previousPublicKeyPayloadSignature);
      }
    }

    // 本地保存needCompress为true即压缩
    if (securityContext.needCompress) {
      //2. 压缩数据
      data = CryptoUtil.compress(data);
    }
    if (securityContext.needEncrypt) {
      //3. 数据加密，base64
      SimplePublicKey? targetPublicKey;
      if (targetPeerId != null && peerId != null && targetPeerId != peerId) {
        targetPublicKey = await peerClientService.getPublicKey(targetPeerId);
      } else {
        // 本地保存前加密
        targetPublicKey = myself.publicKey;
      }
      if (targetPublicKey == null) {
        logger.e("TargetPublicKey is null, will not be encrypted!");
        throw 'without TargetPublicKey';
      }

      // 目标公钥不为空时加密数据
      if (securityContext.payloadKey != null) {
        /// 安全上下文中没有加密key表示第一次加密，key随机数产生，
        /// 否则表示第n次，要采用同样的加密key做多次加密
        List<int>? secretKey = securityContext.secretKey;
        if (secretKey == null) {
          if (securityContext.payloadKey != '') {
            var privateKey = myself.privateKey;
            if (privateKey != null) {
              secretKey = await cryptoGraphy.eccDecrypt(
                  CryptoUtil.decodeBase64(securityContext.payloadKey!),
                  localKeyPair: privateKey);
            }
          }
          secretKey ??= await cryptoGraphy.getRandomBytes();
          result.secretKey = secretKey;
        }
        data = await cryptoGraphy.aesEncrypt(data, secretKey);
        // 对对称密钥进行目标公钥加密
        var encryptedKey = await cryptoGraphy.eccEncrypt(secretKey,
            remotePublicKey: targetPublicKey);
        result.payloadKey = CryptoUtil.encodeBase64(encryptedKey);
      } else {
        data = await cryptoGraphy.eccEncrypt(data,
            remotePublicKey: targetPublicKey);
      }
    }
    // 无论是否经过压缩和加密，进行based64处理
    result.transportPayload = CryptoUtil.encodeBase64(data);
    // 设置数据的hash，base64
    var payloadHash = await cryptoGraphy.hash(data);
    var payloadHashBase64 = CryptoUtil.encodeBase64(payloadHash);
    result.payloadHash = payloadHashBase64;

    return result;
  }

  /// 加密参数必须有是否压缩，是否加密，源peerId，目标peerId，加密键值，签名
  /// 返回负载
  /// @param payload
  /// @param securityParams
  static Future<List<int>> decrypt(
      String transportPayload, SecurityContext securityContext) async {
    var targetPeerId = securityContext.targetPeerId;
    var peerId = myself.peerId;
    List<int> data = CryptoUtil.decodeBase64(transportPayload);
    // 本地保存前加密targetPeerId可为空
    if (targetPeerId == null || targetPeerId == peerId) {
      // 消息的数据部分，base64
      var needEncrypt = securityContext.needEncrypt;
      if (needEncrypt) {
        var privateKey = myself.privateKey;
        if (privateKey == null) {
          throw 'NullPrivateKey';
        }
        // 1.对对称密钥进行私钥解密
        var payloadKey = securityContext.payloadKey;
        // 如果存在加密密钥，对密钥进行ecc解密
        List<int>? secretKey = securityContext.secretKey;
        if (StringUtil.isNotEmpty(payloadKey) || secretKey != null) {
          if (secretKey == null) {
            try {
              secretKey = await cryptoGraphy.eccDecrypt(
                  CryptoUtil.decodeBase64(payloadKey!),
                  localKeyPair: privateKey);
            } catch (e) {
              logger.e(e.toString());
            }
          }
          var i = 0;
          while (secretKey == null && i < myself.expiredKeys.length) {
            try {
              secretKey = await cryptoGraphy.eccDecrypt(
                  CryptoUtil.decodeBase64(payloadKey!),
                  localKeyPair: myself.expiredKeys[i]);
            } catch (e) {
              logger.e(e.toString());
            } finally {
              i++;
            }
          }
          if (secretKey == null) {
            throw 'EccDecryptFailed';
          }
          // 数据解密
          data = await cryptoGraphy.aesDecrypt(data, secretKey);
        } else {
          //直接ecc数据解密
          data = await cryptoGraphy.eccDecrypt(data, localKeyPair: privateKey);
        }
      }

      var needCompress = securityContext.needCompress;
      if (needCompress) {
        // 2. 解压缩
        data = CryptoUtil.uncompress(data);
      }
      //3. 消息的数据部分，验证签名
      var needSign = securityContext.needSign;
      if (needSign) {
        var payloadSignature = securityContext.payloadSignature;
        if (payloadSignature != null) {
          SimplePublicKey? srcPublicKey;
          var srcPeerId = securityContext.srcPeerId;
          if (srcPeerId != null && peerId != null && srcPeerId != peerId) {
            srcPublicKey = await peerClientService.getPublicKey(srcPeerId);
          } else {
            throw 'NullSrcPeerId';
            // 本地保存前加密如果签名，验签需尝试所有expiredPublicKey
            //srcPublicKey = myself.publicKey
          }
          if (srcPublicKey == null) {
            throw 'NullSrcPublicKey';
          }
          var pass = await cryptoGraphy.verify(data, payloadSignature.codeUnits,
              publicKey: srcPublicKey);
          if (!pass) {
            var previousPublicKeyPayloadSignature =
                securityContext.previousPublicKeyPayloadSignature;
            if (previousPublicKeyPayloadSignature != null) {
              pass = await cryptoGraphy.verify(
                  data, previousPublicKeyPayloadSignature.codeUnits,
                  publicKey: srcPublicKey);
            }

            var srcPeerId = securityContext.srcPeerId;
            if (!pass && srcPeerId != null) {
              var peerClients = [
                peerClientService.findCachedOneByPeerId(srcPeerId)
              ];
              if (peerClients.isNotEmpty) {
                srcPublicKey = await peerClientService.getPublicKey(srcPeerId);
                if (srcPublicKey != null) {
                  pass = await cryptoGraphy.verify(
                      data, payloadSignature.codeUnits,
                      publicKey: srcPublicKey);
                } else {
                  throw 'NullSrcPublicKey';
                }
              }
              if (!pass) {
                logger.e("PayloadVerifyFailure");
                //throw new Error("PayloadVerifyFailure")
              }
            } else {
              logger.e("PeerClientNotExists");
            }
          }
        }
      }
    }

    return data;
  }
}
