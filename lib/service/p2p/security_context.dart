import 'dart:typed_data';

import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/signalprotocol.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:cryptography/cryptography.dart';

///0表示不会根据长度来决定是否压缩
const int compressLimit = 0; //2048;

///数据压缩加密的通用接口，提供加密和解密两个方法
abstract class SecurityContextService {
  Future<bool> encrypt(SecurityContext securityContext);

  Future<bool> decrypt(SecurityContext securityContext);
}

class CommonSecurityContextService extends SecurityContextService {
  ///加密，而且把二进制数据base64转换成为securityContext的transportPayload字段String
  @override
  Future<bool> encrypt(SecurityContext securityContext) async {
    int cryptoOptionIndex = securityContext.cryptoOptionIndex;
    if (cryptoOptionIndex == CryptoOption.linkman.index) {
      return linkmanCryptographySecurityContextService.encrypt(securityContext);
    } else if (cryptoOptionIndex == CryptoOption.group.index) {
      return groupCryptographySecurityContextService.encrypt(securityContext);
    } else if (cryptoOptionIndex == CryptoOption.signal.index) {
      return signalCryptographySecurityContextService.encrypt(securityContext);
    } else if (cryptoOptionIndex == CryptoOption.none.index) {
      return noneSecurityContextService.encrypt(securityContext);
    } else if (cryptoOptionIndex == CryptoOption.compress.index) {
      return compressSecurityContextService.encrypt(securityContext);
    }
    return linkmanCryptographySecurityContextService.encrypt(securityContext);
  }

  ///解密，而且把String数据base64转换成为二进制的返回数据
  @override
  Future<bool> decrypt(SecurityContext securityContext) async {
    int cryptoOptionIndex = securityContext.cryptoOptionIndex;
    if (cryptoOptionIndex == CryptoOption.linkman.index) {
      return linkmanCryptographySecurityContextService.decrypt(securityContext);
    } else if (cryptoOptionIndex == CryptoOption.group.index) {
      return groupCryptographySecurityContextService.decrypt(securityContext);
    } else if (cryptoOptionIndex == CryptoOption.signal.index) {
      return signalCryptographySecurityContextService.decrypt(securityContext);
    } else if (cryptoOptionIndex == CryptoOption.none.index) {
      return noneSecurityContextService.decrypt(securityContext);
    } else if (cryptoOptionIndex == CryptoOption.compress.index) {
      return compressSecurityContextService.decrypt(securityContext);
    }
    return linkmanCryptographySecurityContextService.decrypt(securityContext);
  }
}

final CommonSecurityContextService commonSecurityContextService =
    CommonSecurityContextService();

class NoneSecurityContextService extends SecurityContextService {
  NoneSecurityContextService();

  /// 加密参数必须有是否压缩，是否加密，目标peerId
  /// 返回参数包括结果负载，是否压缩，是否加密，加密键值，签名
  /// @param payload
  /// @param securityParams
  @override
  Future<bool> encrypt(SecurityContext securityContext) async {
    securityContext.needCompress = false;
    securityContext.needSign = false;
    securityContext.needEncrypt = false;
    logger.i('call none encrypt');
    return linkmanCryptographySecurityContextService.encrypt(securityContext);
  }

  /// 加密参数必须有是否压缩，是否加密，源peerId，目标peerId，加密键值，签名
  /// 返回负载
  /// @param payload
  /// @param securityParams
  @override
  Future<bool> decrypt(SecurityContext securityContext) async {
    securityContext.needCompress = false;
    securityContext.needSign = false;
    securityContext.needEncrypt = false;
    logger.i('call none decrypt');
    return linkmanCryptographySecurityContextService.decrypt(securityContext);
  }
}

final NoneSecurityContextService noneSecurityContextService =
    NoneSecurityContextService();

class CompressSecurityContextService extends SecurityContextService {
  CompressSecurityContextService();

  /// 加密参数必须有是否压缩，是否加密，目标peerId
  /// 返回参数包括结果负载，是否压缩，是否加密，加密键值，签名
  /// @param payload
  /// @param securityParams
  @override
  Future<bool> encrypt(SecurityContext securityContext) async {
    securityContext.needCompress = true;
    securityContext.needSign = false;
    securityContext.needEncrypt = false;
    logger.i('call compress encrypt');
    return linkmanCryptographySecurityContextService.encrypt(securityContext);
  }

  /// 加密参数必须有是否压缩，是否加密，源peerId，目标peerId，加密键值，签名
  /// 返回负载
  /// @param payload
  /// @param securityParams
  @override
  Future<bool> decrypt(SecurityContext securityContext) async {
    securityContext.needCompress = true;
    securityContext.needSign = false;
    securityContext.needEncrypt = false;
    logger.i('call uncompress decrypt');
    return linkmanCryptographySecurityContextService.decrypt(securityContext);
  }
}

final CompressSecurityContextService compressSecurityContextService =
    CompressSecurityContextService();

/// 对任意结构的负载进行压缩，签名，加密处理，加密采用普通的非对称和对称加密
abstract class CryptographySecurityContextService
    extends SecurityContextService {
  CryptographySecurityContextService();

  /// 加密参数必须有是否压缩，是否加密，目标peerId
  /// 返回参数包括结果负载，是否压缩，是否加密，加密键值，签名
  /// @param payload
  /// @param securityParams
  @override
  Future<bool> encrypt(SecurityContext securityContext) async {
    bool result = true;
    dynamic payload = securityContext.payload;
    bool needEncrypt = securityContext.needEncrypt;
    bool needCompress = securityContext.needCompress;
    bool needSign = securityContext.needSign;
    if (!needEncrypt && !needCompress && !needSign) {
      return true;
    }
    List<int> data = JsonUtil.toUintList(payload);
    List<int>? secretKey = securityContext.secretKey;
    if (secretKey != null) {
      logger.w(
          'secretKey is exist,needSign:$needSign,needCompress:$needCompress');
    }
    // 1.设置签名（本地保存前加密不签名），只有在加密的情况下才设置签名
    var peerId = myself.peerId;
    if (needSign) {
      if (peerId != null) {
        /// 签名，并且用上一次过期的私钥也签名
        var myselfPrivateKey = myself.privateKey;
        if (myselfPrivateKey == null) {
          logger.e("myselfPrivateKey is null, will not be signed!");
          return false;
        }
        var payloadSignature = await cryptoGraphy.sign(data, myselfPrivateKey);
        securityContext.payloadSignature =
            CryptoUtil.encodeBase64(payloadSignature);
        if (myself.expiredKeys.isNotEmpty) {
          var previousPublicKeyPayloadSignature =
              await cryptoGraphy.sign(data, myself.expiredKeys[0]);
          securityContext.previousPublicKeyPayloadSignature =
              CryptoUtil.encodeBase64(previousPublicKeyPayloadSignature);
        }
      } else {
        logger.e("myself is null, will not be signed!");
        return false;
      }
    }
    //2. 压缩数据
    if (needCompress) {
      if (data.length < compressLimit) {
        securityContext.needCompress = false;
        needCompress = false;
      } else {
        try {
          data = CryptoUtil.compress(data);
        } catch (err) {
          logger.e("compress failure:$err");
          securityContext.needCompress = false;
          needCompress = false;
        }
      }
    }
    //3. 数据加密
    if (needEncrypt) {
      data = await pureEncrypt(securityContext, data);
    }

    // 设置数据的hash，base64
    var payloadHash = await cryptoGraphy.hash(data);
    var payloadHashBase64 = CryptoUtil.encodeBase64(payloadHash);
    securityContext.payloadHash = payloadHashBase64;
    securityContext.payload = data;

    return result;
  }

  Future<List<int>> pureEncrypt(
      SecurityContext securityContext, List<int> data);

  /// 加密参数必须有是否压缩，是否加密，源peerId，目标peerId，加密键值，签名
  /// 返回负载
  /// @param payload
  /// @param securityParams
  @override
  Future<bool> decrypt(SecurityContext securityContext) async {
    bool result = true;
    dynamic payload = securityContext.payload;
    List<int> data = JsonUtil.toUintList(payload);
    bool needEncrypt = securityContext.needEncrypt;
    bool needCompress = securityContext.needCompress;
    bool needSign = securityContext.needSign;
    if (!needEncrypt && !needCompress && !needSign) {
      return true;
    }
    var targetPeerId = securityContext.targetPeerId;
    var peerId = myself.peerId;
    if (targetPeerId != null && peerId != null && targetPeerId != peerId) {
      logger.e('targetPeerId is not myself');
      return false;
    }

    // 1. 解密
    if (needEncrypt) {
      data = await pureDecrypt(securityContext, data);
    }
    // 2. 解压缩
    if (needCompress) {
      try {
        data = CryptoUtil.uncompress(data);
      } catch (err) {
        logger.e("uncompress failure:$err");
        securityContext.needCompress = false;
        needCompress = false;
      }
    }
    //3. 消息的数据部分，验证签名
    if (needSign) {
      var payloadSignature = securityContext.payloadSignature;
      if (payloadSignature != null) {
        SimplePublicKey? srcPublicKey;
        var srcPeerId = securityContext.srcPeerId;
        if (srcPeerId != null && peerId != null && srcPeerId != peerId) {
          srcPublicKey = await peerClientService.getCachedPublicKey(srcPeerId);
        } else {
          logger.e('Null SrcPeerId,cannot verify signature');
          return false;
          // 本地保存前加密如果签名，验签需尝试所有expiredPublicKey
          //srcPublicKey = myself.publicKey
        }
        if (srcPublicKey == null) {
          logger.e('NullSrcPublicKey');
          return false;
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
              srcPublicKey =
                  await peerClientService.getCachedPublicKey(srcPeerId);
              if (srcPublicKey != null) {
                pass = await cryptoGraphy.verify(
                    data, payloadSignature.codeUnits,
                    publicKey: srcPublicKey);
              } else {
                logger.e('NullSrcPublicKey');
                return false;
              }
            }
            if (!pass) {
              logger.e("PayloadVerifyFailure");
              return false;
            }
          } else {
            logger.e("PeerClientNotExists");
            return false;
          }
        } else {
          logger.e("PayloadVerifyFailure");
          return false;
        }
      } else {
        logger.e("payloadSignature is null, cannot verify signature");
        return false;
      }
    }
    securityContext.payload = data;

    return result;
  }

  Future<List<int>> pureDecrypt(
      SecurityContext securityContext, List<int> data);
}

///点对点的加密方式，使用对方的公钥和自己的私钥加密
///所以payloadKey为空
class LinkmanCryptographySecurityContextService
    extends CryptographySecurityContextService {
  LinkmanCryptographySecurityContextService();

  @override
  Future<List<int>> pureEncrypt(
      SecurityContext securityContext, List<int> data) async {
    var targetPeerId = securityContext.targetPeerId;
    var peerId = myself.peerId;
    SimplePublicKey? targetPublicKey;
    if (targetPeerId != null && peerId != null && targetPeerId != peerId) {
      targetPublicKey = await linkmanService.getCachedPublicKey(targetPeerId);
    } else {
      // 本地保存前加密
      targetPublicKey = myself.publicKey;
    }
    if (targetPublicKey == null) {
      logger.e("TargetPublicKey is null, will not be encrypted!");
      return data;
    }

    //直接加密，不用给定的密钥
    logger.i('linkman encrypt');
    data =
        await cryptoGraphy.eccEncrypt(data, remotePublicKey: targetPublicKey);

    return data;
  }

  @override
  Future<List<int>> pureDecrypt(
      SecurityContext securityContext, List<int> data) async {
    var privateKey = myself.privateKey;
    if (privateKey == null) {
      logger.e('NullPrivateKey');
      return data;
    }
    //直接ecc数据解密
    data = await cryptoGraphy.eccDecrypt(data, localKeyPair: privateKey);

    return data;
  }
}

final LinkmanCryptographySecurityContextService
    linkmanCryptographySecurityContextService =
    LinkmanCryptographySecurityContextService();

///群加密方式，加密随机生成的密钥，用共同的密钥加密内容，然后再加密密钥
///加密密钥放在数据的后面
///secretKey存放明文的密钥，直接用于后续的加密，不能传输
class GroupCryptographySecurityContextService
    extends CryptographySecurityContextService {
  GroupCryptographySecurityContextService();

  @override
  Future<List<int>> pureEncrypt(
      SecurityContext securityContext, List<int> data) async {
    var targetPeerId = securityContext.targetPeerId;
    var peerId = myself.peerId;
    SimplePublicKey? targetPublicKey;
    if (targetPeerId != null && peerId != null && targetPeerId != peerId) {
      targetPublicKey = await linkmanService.getCachedPublicKey(targetPeerId);
    } else {
      // 本地保存前加密
      targetPublicKey = myself.publicKey;
    }
    if (targetPublicKey == null) {
      logger.e("TargetPublicKey is null, will not be encrypted!");
      return data;
    }

    /// 安全上下文中没有加密key表示第一次加密，key随机数产生，
    /// 否则表示第n次，要采用同样的加密key做多次加密
    List<int>? secretKey = securityContext.secretKey;
    logger.i('group encrypt and secretKey:${secretKey != null}');
    if (secretKey == null) {
      secretKey = await cryptoGraphy.getRandomBytes();
      securityContext.secretKey = secretKey;
      data = await cryptoGraphy.aesEncrypt(data, secretKey);
    }
    // 对对称密钥进行目标公钥加密
    var encryptedKey = await cryptoGraphy.eccEncrypt(secretKey,
        remotePublicKey: targetPublicKey);

    ///返回密钥的密文
    securityContext.payloadKey = CryptoUtil.encodeBase64(encryptedKey);

    return data;
  }

  @override
  Future<List<int>> pureDecrypt(
      SecurityContext securityContext, List<int> data) async {
    var privateKey = myself.privateKey;
    if (privateKey == null) {
      logger.e('NullPrivateKey');
      return data;
    }

    // 1.对对称密钥进行私钥解密
    // 如果存在加密密钥，对密钥进行ecc解密
    List<int>? secretKey = securityContext.secretKey;
    if (secretKey == null) {
      List<int> payloadKey =
          CryptoUtil.decodeBase64(securityContext.payloadKey!);
      try {
        secretKey =
            await cryptoGraphy.eccDecrypt(payloadKey, localKeyPair: privateKey);
      } catch (e) {
        logger.e(e.toString());
        var i = 0;
        while (secretKey == null && i < myself.expiredKeys.length) {
          try {
            secretKey = await cryptoGraphy.eccDecrypt(payloadKey,
                localKeyPair: myself.expiredKeys[i]);
          } catch (e) {
            logger.e(e.toString());
          } finally {
            i++;
          }
        }
      }
    }
    if (secretKey == null) {
      logger.e('EccDecryptFailed');
      return data;
    }
    // 数据解密
    data = await cryptoGraphy.aesDecrypt(data, secretKey);

    return data;
  }
}

final GroupCryptographySecurityContextService
    groupCryptographySecurityContextService =
    GroupCryptographySecurityContextService();

/// 对任意结构的负载进行压缩，签名，加密处理，采用signal协议轮轮式加密
class SignalCryptographySecurityContextService
    extends CryptographySecurityContextService {
  SignalCryptographySecurityContextService();

  @override
  Future<List<int>> pureEncrypt(
      SecurityContext securityContext, List<int> data) async {
    var targetPeerId = securityContext.targetPeerId;
    var targetClientId = securityContext.targetClientId;
    SignalSession? signalSession =
        signalSessionPool.get(peerId: targetPeerId!, clientId: targetClientId!);
    if (signalSession != null) {
      data = await signalSession.encrypt(Uint8List.fromList(data));
      logger.i('call signal encrypt');
    } else {
      logger.e(
          'encrypt signalSession:$targetPeerId,targetClientId:$targetClientId is not exist');
    }
    return data;
  }

  @override
  Future<List<int>> pureDecrypt(
      SecurityContext securityContext, List<int> data) async {
    var srcPeerId = securityContext.srcPeerId;
    var targetClientId = securityContext.targetClientId;
    SignalSession? signalSession =
        signalSessionPool.get(peerId: srcPeerId!, clientId: targetClientId!);
    if (signalSession != null) {
      try {
        data = await signalSession.decrypt(data);
        logger.i('call signal decrypt');
      } catch (err) {
        logger.e(
            'signalSession.decrypt signalSession:$srcPeerId,targetClientId:$targetClientId error:$err');
      }
    } else {
      logger.e(
          'decrypt signalSession:$srcPeerId,targetClientId:$targetClientId is not exist');
    }
    return data;
  }
}

final SignalCryptographySecurityContextService
    signalCryptographySecurityContextService =
    SignalCryptographySecurityContextService();
