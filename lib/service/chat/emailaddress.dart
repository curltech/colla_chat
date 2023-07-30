import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/emailaddress.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';

class EmailAddressService extends GeneralBaseService<EmailAddress> {
  EmailAddressService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const [
      'password',
    ],
  }) {
    post = (Map map) {
      return EmailAddress.fromJson(map);
    };
  }

  Future<List<EmailAddress>> findAllMailAddress() async {
    var mailAddress = await find();
    return mailAddress;
  }

  Future<EmailAddress?> findByMailAddress(String email) async {
    var mailAddress = await findOne(
      where: 'email=?',
      whereArgs: [email],
    );
    return mailAddress;
  }

  store(EmailAddress mailAddress) async {
    EmailAddress? old = await findByMailAddress(mailAddress.email);
    if (old != null) {
      mailAddress.id = old.id;
      await update(mailAddress);
    } else {
      await insert(mailAddress);
    }
  }

  ///加密邮件消息，如果参数有密钥，直接对称加密数据
  ///参数无密钥，要么对非组的消息或者拆分后的群消息进行linkman方式加密，
  ///要么对组消息进行加密，返回可发送的多条消息
  Future<PlatformEncryptData?> encrypt(List<int> data, List<String> peerIds,
      {CryptoOption? cryptoOption, List<int>? secretKey}) async {
    SecurityContext securityContext = SecurityContext();
    if (secretKey != null) {
      ///如果有密钥，设置目标为空，直接用密钥对数据进行对称加密
      ///不处理密钥
      securityContext.cryptoOptionIndex = CryptoOption.group.index;
      securityContext.secretKey = secretKey;
      securityContext.targetPeerId = null;
      securityContext.payload = data;
      bool result = await groupCryptographySecurityContextService
          .encrypt(securityContext);
      if (result) {
        data = CryptoUtil.concat(
            securityContext.payload, [CryptoOption.group.index]);

        return PlatformEncryptData(data, secretKey: securityContext.secretKey);
      }
      return null;
    }

    if (cryptoOption == null) {
      if (peerIds.length == 1) {
        cryptoOption = CryptoOption.linkman;
      } else {
        cryptoOption = CryptoOption.group;
      }
    }
    int cryptOptionIndex = cryptoOption.index;
    securityContext.cryptoOptionIndex = cryptOptionIndex;
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOptionIndex];
    securityContextService =
        securityContextService ?? linkmanCryptographySecurityContextService;

    securityContext.payload = data;
    if (cryptoOption == CryptoOption.linkman) {
      String receiverPeerId = peerIds[0];
      Linkman? linkman =
          await linkmanService.findCachedOneByPeerId(receiverPeerId);
      if (linkman != null) {
        securityContext.targetPeerId = receiverPeerId;
        securityContext.targetClientId = linkman.clientId;
      }
      bool result = await securityContextService.encrypt(securityContext);
      if (result) {
        data = CryptoUtil.concat(
            securityContext.payload, [CryptoOption.linkman.index]);

        return PlatformEncryptData(data);
      }
    } else if (cryptoOption == CryptoOption.group) {
      ///再根据群进行消息的复制成多条进行处理
      if (peerIds.isNotEmpty) {
        ///没有密钥，则在第一条的时候会生成新的密钥，处理数据，每一条都处理第一条生成的密钥
        Map<String, String> payloadKeys = {};
        int i = 0;
        for (var receiverPeerId in peerIds) {
          Linkman? linkman =
              await linkmanService.findCachedOneByPeerId(receiverPeerId);
          if (linkman != null) {
            securityContext.targetPeerId = linkman.peerId;
            securityContext.targetClientId = linkman.clientId;
            if (i == 0) {
              securityContext.needSign = false;
              securityContext.needCompress = false;
            } else {
              securityContext.needSign = false;
              securityContext.needCompress = false;
            }
            bool result = await securityContextService.encrypt(securityContext);
            if (result) {
              ///对群加密来说，返回的是通用的加密后数据
              payloadKeys[receiverPeerId] = securityContext.payloadKey!;
              if (i == 0) {
                data = CryptoUtil.concat(
                    securityContext.payload, [CryptoOption.group.index]);
              }
            }
          }
          i++;
        }

        return PlatformEncryptData(data,
            secretKey: securityContext.secretKey, payloadKeys: payloadKeys);
      }
    }

    return null;
  }

  ///数据的最后一位是加密方式，linkman还是group，如果是group，payloadKey或者secretKey必须有值
  Future<List<int>?> decrypt(List<int> data,
      {String? payloadKey, List<int>? secretKey}) async {
    ///数据的最后一位是加密方式
    int cryptOption = data[data.length - 1];
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOption];
    securityContextService =
        securityContextService ?? noneSecurityContextService;
    SecurityContext securityContext = SecurityContext();
    securityContext.payload = data.sublist(0, data.length - 1);
    if (cryptOption == CryptoOption.group.index) {
      if (payloadKey == null && secretKey == null) {
        logger.e('group cryptOption must has payloadKey or secretKey');
        return null;
      }
      securityContext.payloadKey = payloadKey;
      securityContext.secretKey = secretKey;
    }
    bool result = await securityContextService.decrypt(securityContext);
    if (result) {
      return securityContext.payload;
    }
    return null;
  }
}

final emailAddressService = EmailAddressService(
    tableName: "chat_mailaddress",
    indexFields: ['ownerPeerId', 'email', 'name'],
    fields: ServiceLocator.buildFields(EmailAddress(name: '', email: '@'), []));
