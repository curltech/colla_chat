import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/emailaddress.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';

class EmailAddressService extends GeneralBaseService<EmailAddress> {
  EmailAddressService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
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

  ///加密邮件消息，要么对非组的消息或者拆分后的群消息进行linkman方式加密，
  ///要么对组消息进行加密，返回可发送的多条消息
  Future<PlatformEncryptData?> encrypt(List<int> data, List<String> peerIds,
      {CryptoOption? cryptoOption, List<int>? secretKey}) async {
    if (cryptoOption == null) {
      if (peerIds.length == 1) {
        cryptoOption = CryptoOption.linkman;
      } else {
        cryptoOption = CryptoOption.group;
      }
    }
    int cryptOptionIndex = cryptoOption.index;
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOptionIndex];
    securityContextService =
        securityContextService ?? linkmanCryptographySecurityContextService;
    SecurityContext securityContext = SecurityContext();
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
      securityContext.secretKey = secretKey;

      ///再根据群进行消息的复制成多条进行处理
      if (peerIds.isNotEmpty) {
        Map<String, String> payloadKeys = {};
        for (var receiverPeerId in peerIds) {
          Linkman? linkman =
              await linkmanService.findCachedOneByPeerId(receiverPeerId);
          if (linkman != null) {
            securityContext.targetPeerId = linkman.peerId;
            securityContext.targetClientId = linkman.clientId;
            bool result = await securityContextService.encrypt(securityContext);
            if (result) {
              ///对群加密来说，返回的是通用的加密后数据
              payloadKeys[receiverPeerId] = securityContext.payloadKey!;
            }
          }
        }
        data = CryptoUtil.concat(
            securityContext.payload, [CryptoOption.group.index]);

        return PlatformEncryptData(data,
            secretKey: securityContext.secretKey, payloadKeys: payloadKeys);
      } else {
        securityContext.secretKey = secretKey;
        bool result = await securityContextService.encrypt(securityContext);
        if (result) {
          data = CryptoUtil.concat(
              securityContext.payload, [CryptoOption.group.index]);

          return PlatformEncryptData(data,
              secretKey: securityContext.secretKey);
        }
      }
    }

    return null;
  }

  Future<List<int>?> decrypt(List<int> data, String payloadKey) async {
    ///数据的最后一位是加密方式，还有32位的加密的密钥
    int cryptOption = data[data.length - 1];
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOption];
    securityContextService =
        securityContextService ?? noneSecurityContextService;
    SecurityContext securityContext = SecurityContext();
    if (cryptOption == CryptoOption.linkman.index) {
      securityContext.payload = data.sublist(0, data.length - 1);
    } else if (cryptOption == CryptoOption.group.index) {
      securityContext.payload = data.sublist(0, data.length - 1);
      securityContext.payloadKey = payloadKey;
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
