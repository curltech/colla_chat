import 'dart:async';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:telephony/telephony.dart';

onBackgroundMessage(SmsMessage message) async {
  smsClient.onMessage(message);
}

///短信访问客户端，android测试通过
class SmsClient extends IWebClient {
  final Telephony telephony = Telephony.backgroundInstance;
  SmsSendStatusListener? listener;
  StreamController<SmsMessage> smsMessageStreamController =
      StreamController<SmsMessage>();

  SmsClient() {
    listener = (SendStatus status) {
      logger.i(status.toString());
    };
    telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          onMessage(message);
        },
        onBackgroundMessage: onBackgroundMessage);
  }

  ///接收到加密的短信
  onMessage(SmsMessage smsMessage) async {
    smsMessageStreamController.add(smsMessage);
  }

  Future<bool> sendMsg(String message, String mobile,
      {bool defaultApp = false}) async {
    try {
      await telephony.sendSms(
          to: mobile,
          message: message,
          isMultipart: true,
          statusListener: (SendStatus status) {
            logger.i(status.toString());
          });

      return Future.value(true);
    } catch (e) {
      logger.e('send message failure:$e');
    }
    return Future.value(false);
  }

  @override
  dynamic send(String url, dynamic data) async {
    String message;
    if (data is String) {
      message = data;
    } else {
      message = JsonUtil.toJsonString(data);
    }
    return await sendMsg(message, url);
  }

  @override
  dynamic get(String address) async {
    List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals(address),
        sortOrder: [
          OrderBy(SmsColumn.ADDRESS, sort: Sort.ASC),
          OrderBy(SmsColumn.BODY)
        ]);
    return messages;
  }

  Future<List<SmsMessage>> getInboxSms(String address, String keyword) async {
    List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
        filter: SmsFilter.where(SmsColumn.ADDRESS)
            .equals(address)
            .and(SmsColumn.BODY)
            .like(keyword),
        sortOrder: [
          OrderBy(SmsColumn.ADDRESS, sort: Sort.ASC),
          OrderBy(SmsColumn.BODY)
        ]);
    return messages;
  }

  Future<List<SmsConversation>> getConversations() async {
    List<SmsConversation> messages = await telephony.getConversations(
        filter: ConversationFilter.where(ConversationColumn.MSG_COUNT)
            .equals("4")
            .and(ConversationColumn.THREAD_ID)
            .greaterThan("12"),
        sortOrder: [OrderBy(ConversationColumn.THREAD_ID, sort: Sort.ASC)]);

    return messages;
  }

  dynamic sendMessage(dynamic data, String targetPeerId, String targetClientId,
      {CryptoOption cryptoOption = CryptoOption.linkman}) async {
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(targetPeerId);
    if (linkman != null) {
      var mobile = linkman.mobile;
      int cryptOptionIndex = cryptoOption.index;
      SecurityContextService? securityContextService =
          ServiceLocator.securityContextServices[cryptOptionIndex];
      securityContextService =
          securityContextService ?? linkmanCryptographySecurityContextService;
      SecurityContext securityContext = SecurityContext();
      securityContext.targetPeerId = targetPeerId;
      securityContext.targetClientId = targetClientId;
      String jsonStr;
      if (data is String) {
        jsonStr = data;
      } else {
        jsonStr = JsonUtil.toJsonString(data);
      }
      List<int> payload = CryptoUtil.stringToUtf8(jsonStr);
      securityContext.payload = payload;
      bool result = await securityContextService.encrypt(securityContext);
      if (result) {
        data = CryptoUtil.concat(securityContext.payload, [cryptOptionIndex]);
        return await send(mobile!, CryptoUtil.encodeBase64(data));
      }
    }
  }
}

final SmsClient smsClient = SmsClient();

///高级短信访问客户端
// class AdvancedSmsClient extends IWebClient {
//   final sms_advanced.SmsQuery query = sms_advanced.SmsQuery();
//   final sms_advanced.SmsSender sender = sms_advanced.SmsSender();
//   final sms_advanced.SmsReceiver receiver = sms_advanced.SmsReceiver();
//
//   AdvancedSmsClient() {
//     receiver.onSmsReceived?.listen((sms_advanced.SmsMessage message) {
//       onMessage(message);
//     });
//   }
//
//   Future<bool> sendMsg(String message, String mobile,
//       {bool defaultApp = false}) async {
//     try {
//       sms_advanced.SmsMessage smsMessage =
//           sms_advanced.SmsMessage(mobile, message);
//       smsMessage.onStateChanged.listen((state) {
//         if (state == sms_advanced.SmsMessageState.Sent) {
//           logger.i("sms_advanced sms is sent!");
//         } else if (state == sms_advanced.SmsMessageState.Delivered) {
//           logger.i("sms_advanced sms is delivered!");
//         }
//       });
//       sender.sendSms(smsMessage);
//
//       return Future.value(true);
//     } catch (e) {
//       logger.e('send message failure:$e');
//     }
//     return Future.value(false);
//   }
//
//   @override
//   dynamic send(String url, dynamic data) async {
//     String message;
//     if (data is String) {
//       message = data;
//     } else {
//       message = JsonUtil.toJsonString(data);
//     }
//     return await sendMsg(message, url);
//   }
//
//   @override
//   dynamic get(String address) async {
//     List<sms_advanced.SmsMessage> messages =
//         await query.querySms(address: address);
//
//     return messages;
//   }
//
//   Future<List<sms_advanced.SmsMessage>> getInboxSms(String address) async {
//     List<sms_advanced.SmsMessage> messages =
//         await query.querySms(address: address);
//
//     return messages;
//   }
//
//   onMessage(sms_advanced.SmsMessage message) async {
//     var mobile = message.address;
//     String? body = message.body;
//     if (body == null) {
//       return;
//     }
//     logger
//         .i('${DateTime.now().toUtc()}:got a message from mobile: $mobile sms');
//     List<Linkman> linkmen = await linkmanService.findByMobile(mobile!);
//     if (linkmen.isEmpty) {
//       return;
//     }
//     Linkman? linkman = linkmen[0];
//     var peerId = linkman.peerId;
//     var clientId = linkman.clientId;
//     Uint8List data = CryptoUtil.decodeBase64(body);
//     int cryptOption = data[data.length - 1];
//     SecurityContextService? securityContextService =
//         ServiceLocator.securityContextServices[cryptOption];
//     securityContextService =
//         securityContextService ?? noneSecurityContextService;
//     SecurityContext securityContext = SecurityContext();
//     securityContext.srcPeerId = peerId;
//     securityContext.targetClientId = clientId;
//     securityContext.payload = data.sublist(0, data.length - 1);
//     bool result = await securityContextService.decrypt(securityContext);
//     if (result) {
//       body = CryptoUtil.utf8ToString(securityContext.payload);
//       ChatMessage chatMessage = await chatMessageService.buildChatMessage(
//         receiverPeerId: myself.peerId,
//         receiverName: myself.name,
//         content: body,
//         transportType: TransportType.sms,
//       );
//       chatMessage.senderPeerId = linkman.peerId;
//       chatMessage.senderClientId = linkman.clientId;
//       chatMessage.senderName = linkman.name;
//       globalChatMessageController.receiveChatMessage(chatMessage);
//     }
//   }
//
//   dynamic sendMessage(dynamic data, String targetPeerId, String targetClientId,
//       {CryptoOption cryptoOption = CryptoOption.cryptography}) async {
//     Linkman? linkman = await linkmanService.findCachedOneByPeerId(targetPeerId);
//     if (linkman != null) {
//       var mobile = linkman.mobile;
//       int cryptOptionIndex = cryptoOption.index;
//       SecurityContextService? securityContextService =
//           ServiceLocator.securityContextServices[cryptOptionIndex];
//       securityContextService =
//           securityContextService ?? cryptographySecurityContextService;
//       SecurityContext securityContext = SecurityContext();
//       securityContext.targetPeerId = targetPeerId;
//       securityContext.targetClientId = targetClientId;
//       String jsonStr;
//       if (data is String) {
//         jsonStr = data;
//       } else {
//         jsonStr = JsonUtil.toJsonString(data);
//       }
//       List<int> payload = CryptoUtil.stringToUtf8(jsonStr);
//       securityContext.payload = payload;
//       bool result = await securityContextService.encrypt(securityContext);
//       if (result) {
//         data = CryptoUtil.concat(securityContext.payload, [cryptOptionIndex]);
//         return await send(mobile!, CryptoUtil.encodeBase64(data));
//       }
//     }
//   }
// }
//
// final AdvancedSmsClient advancedSmsClient = AdvancedSmsClient();
