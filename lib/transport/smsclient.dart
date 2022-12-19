import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:telephony/telephony.dart';

onBackgroundMessage(SmsMessage message) async {
  smsClientPool.onMessage(message);
}

class MobileState {
  final Telephony telephony = Telephony.backgroundInstance;

  // Check if a device is capable of sending SMS
  Future<bool?> isSmsCapable() async {
    bool? canSendSms = await telephony.isSmsCapable;

    return canSendSms;
  }

  // Get sim state
  Future<SimState> simState() async {
    SimState simState = await telephony.simState;

    return simState;
  }

  Future<bool?> requestPhoneAndSmsPermissions() async {
    bool? success = await telephony.requestPhoneAndSmsPermissions;

    return success;
  }

  Future<void> dialPhoneNumber(String mobile) async {
    return await telephony.dialPhoneNumber(mobile);
  }

  Future<void> openDialer(String mobile) async {
    return await telephony.openDialer(mobile);
  }
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
          // Handle message
          onMessage(message);
        },
        onBackgroundMessage: onBackgroundMessage);
  }

  @override
  register(String name, Function func) {}

  sendMsg(String message, String mobile, {bool defaultApp = false}) async {
    var result = telephony.sendSms(
        to: mobile,
        message: message,
        isMultipart: true,
        statusListener: (SendStatus status) {
          logger.i(status);
        });
    return result;
  }

  @override
  send(String mobile, dynamic data) async {
    var message = JsonUtil.toJsonString(data);

    return await sendMsg(message, mobile);
  }

  @override
  dynamic get(String mobile) {
    return send(mobile, '');
  }

  onMessage(SmsMessage message) async {
    smsClientPool.onMessage(message);
  }

  Future<List<SmsMessage>> getInboxSms() async {
    List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
        filter: SmsFilter.where(SmsColumn.ADDRESS)
            .equals("1234567890")
            .and(SmsColumn.BODY)
            .like("starwars"),
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
}

class SmsClientPool {
  String mobile;
  final SmsClient smsClient = SmsClient();

  //本机的手机号码
  SmsClientPool(this.mobile);

  onMessage(SmsMessage message) async {
    var mobile = message.address;
    var body = message.body;
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
    var data = CryptoUtil.decodeBase64(body);
    int cryptOption = data[data.length - 1];
    SecurityContextService? securityContextService =
        ServiceLocator.securityContextServices[cryptOption];
    securityContextService =
        securityContextService ?? noneSecurityContextService;
    SecurityContext securityContext = SecurityContext();
    securityContext.srcPeerId = peerId;
    securityContext.clientId = clientId;
    securityContext.payload = data.sublist(0, data.length - 1);
    bool result = await securityContextService.decrypt(securityContext);
    if (result) {
      body = CryptoUtil.utf8ToString(securityContext.payload);
      Map<String, dynamic> json = JsonUtil.toJson(body);
      ChatMessage chatMessage = ChatMessage.fromJson(json);
      chatMessageService.receiveChatMessage(chatMessage);
      // var response =
      //     await chainMessageHandler.receiveRaw(body.codeUnits, '', '');
    }
  }

  Future<void> send(List<int> data, String targetPeerId, String clientId,
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
      securityContext.clientId = clientId;
      //List<int> data = CryptoUtil.stringToUtf8(message);
      securityContext.payload = data;
      bool result = await securityContextService.encrypt(securityContext);
      if (result) {
        data = CryptoUtil.concat(securityContext.payload, [cryptOptionIndex]);
        return await smsClient.send(mobile!, CryptoUtil.encodeBase64(data));
      }
    }
  }
}

final SmsClientPool smsClientPool = SmsClientPool('');
