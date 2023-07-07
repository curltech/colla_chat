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
  Future<Map<String, List<int>>> encrypt(
    List<int> data,
    List<String> peerIds, {
    CryptoOption? cryptoOption,
  }) async {
    Map<String, List<int>> encryptData = {};
    if (cryptoOption == null) {
      if (peerIds.length == 1) {
        cryptoOption = CryptoOption.linkman;
      } else if (peerIds.length > 1) {
        cryptoOption = CryptoOption.group;
      } else {
        return {};
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
      if (receiverPeerId != myself.peerId) {
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
          encryptData[receiverPeerId] = data;

          return encryptData;
        }
      }
    } else if (cryptoOption == CryptoOption.group) {
      ///再根据群进行消息的复制成多条进行处理
      if (peerIds.isNotEmpty) {
        for (var receiverPeerId in peerIds) {
          if (securityContext.secretKey != null) {
            securityContext.needSign = false;
            securityContext.needCompress = false;
          }
          Linkman? linkman =
              await linkmanService.findCachedOneByPeerId(receiverPeerId);
          if (linkman != null) {
            securityContext.targetPeerId = linkman.peerId;
            securityContext.targetClientId = linkman.clientId;
            bool result = await securityContextService.encrypt(securityContext);
            if (result) {
              ///对群加密来说，返回的是通用的加密后数据
              List<int> encryptedKey =
                  CryptoUtil.decodeBase64(securityContext.payloadKey!);
              encryptedKey =
                  CryptoUtil.concat(encryptedKey, [CryptoOption.group.index]);
              data = CryptoUtil.concat(securityContext.payload, encryptedKey);
              encryptData[receiverPeerId] = data;
            }
          }
        }
      }
    }

    return encryptData;
  }

  Future<List<int>?> decrypt(List<int> data) async {
    ///数据的最后一位是加密方式，还有32位的加密的密钥
    int cryptOption = data[data.length - 1];
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOption];
    securityContextService =
        securityContextService ?? noneSecurityContextService;
    SecurityContext securityContext = SecurityContext();
    if (cryptOption == CryptoOption.linkman.index) {
      securityContext.payload = data.sublist(0, data.length - 1);
    }
    if (cryptOption == CryptoOption.group.index) {
      List<int> payloadKey = data.sublist(
          data.length - CryptoGraphy.randomBytesLength - 1, data.length - 1);
      securityContext.payloadKey = CryptoUtil.encodeBase64(payloadKey);
      securityContext.payload =
          data.sublist(0, data.length - CryptoGraphy.randomBytesLength - 1);
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
