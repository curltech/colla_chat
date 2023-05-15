import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:telephony/telephony.dart';

onBackgroundMessage(SmsMessage message) async {
  smsClient.onMessage(message);
}

///短信访问客户端
class SmsClient extends IWebClient {
  final Telephony telephony = Telephony.backgroundInstance;
  SmsSendStatusListener? listener;

  SmsClient() {
    listener = (SendStatus status) {
      logger.i(status);
    };
    telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          onMessage(message);
        },
        onBackgroundMessage: onBackgroundMessage);
  }

  Future<bool> sendMsg(String message, String mobile,
      {bool defaultApp = false}) async {
    try {
      //android下发送有问题
      await telephony.sendSms(
          to: mobile,
          message: message,
          isMultipart: true,
          statusListener: (SendStatus status) {
            logger.i(status);
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

  onMessage(SmsMessage message) async {
    var mobile = message.address;
    String? body = message.body;
    if (body == null) {
      return;
    }
    logger
        .i('${DateTime.now().toUtc()}:got a message from mobile: $mobile sms');
    List<PeerClient> peerClients =
        await peerClientService.findByMobile(mobile!);
    if (peerClients.isEmpty) {
      return;
    }
    PeerClient? peerClient = peerClients[0];
    var peerId = peerClient.peerId;
    var clientId = peerClient.clientId;
    Uint8List data = CryptoUtil.decodeBase64(body);
    int cryptOption = data[data.length - 1];
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOption];
    securityContextService =
        securityContextService ?? noneSecurityContextService;
    SecurityContext securityContext = SecurityContext();
    securityContext.srcPeerId = peerId;
    securityContext.targetClientId = clientId;
    securityContext.payload = data.sublist(0, data.length - 1);
    bool result = await securityContextService.decrypt(securityContext);
    if (result) {
      body = CryptoUtil.utf8ToString(securityContext.payload);
      ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        receiverPeerId: myself.peerId,
        receiverName: myself.name,
        content: body,
        transportType: TransportType.sms,
      );
      chatMessage.senderPeerId = peerClient.peerId;
      chatMessage.senderClientId = peerClient.clientId;
      chatMessage.senderName = peerClient.name;
      globalChatMessageController.receiveChatMessage(chatMessage);
    }
  }

  dynamic sendMessage(dynamic data, String targetPeerId, String targetClientId,
      {CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    PeerClient? peerClient =
        await peerClientService.findCachedOneByPeerId(targetPeerId);
    if (peerClient != null) {
      var mobile = peerClient.mobile;
      int cryptOptionIndex = cryptoOption.index;
      SecurityContextService? securityContextService =
          ServiceLocator.securityContextServices[cryptOptionIndex];
      securityContextService =
          securityContextService ?? cryptographySecurityContextService;
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
        return await smsClient.send(mobile!, CryptoUtil.encodeBase64(data));
      }
    }
  }
}

final SmsClient smsClient = SmsClient();
