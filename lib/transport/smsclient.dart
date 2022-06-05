import 'package:colla_chat/p2p/chain/chainmessagehandler.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:telephony/telephony.dart';
import '../provider/app_data.dart';

var backgrounMessageHandler = (SmsMessage message) async {
  var body = message.body;
  logger.i(body);
  if (body != null) {
    var response = await chainMessageHandler.receiveRaw(body.codeUnits, '', '');
  }
};

class SmsClient implements IWebClient {
  final Telephony telephony = Telephony.backgroundInstance;
  SmsSendStatusListener? listener;
  String address;

  //本机的手机号码
  SmsClient(this.address);

  @override
  register(String name, Function func) {
    listener = (SendStatus status) {
      logger.i(status);
    };
    telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          // Handle message
          backgrounMessageHandler(message);
        },
        onBackgroundMessage: backgrounMessageHandler);
  }

  sendMsg(dynamic data, String recipient) async {
    var result = telephony.sendSms(
        to: recipient,
        message: String.fromCharCodes(data),
        isMultipart: true,
        statusListener: (SendStatus status) {
          logger.i(status);
        });
    return result;
  }

  @override
  send(String url, dynamic data) async {
    return await sendMsg(data, url);
  }

  @override
  dynamic get(String url) {
    return send(url, {});
  }
}

class SmsClientPool {
  static SmsClientPool _instance = SmsClientPool();
  static bool initStatus = false;
  var smsClients = <String, SmsClient>{};

  /// 初始化连接池，smsClient，返回连接池
  static SmsClientPool get instance {
    if (!initStatus) {}
    initStatus = true;

    return _instance;
  }

  SmsClient? _default;

  SmsClientPool();

  SmsClient? get(String address) {
    if (smsClients.containsKey(address)) {
      return smsClients[address];
    } else {
      var smsClient = SmsClient(address);
      smsClients[address] = smsClient;

      return smsClient;
    }
  }

  close(String address) {
    if (smsClients.containsKey(address)) {
      var smsClient = smsClients[address];
      if (smsClient != null) {}
      smsClients.remove(address);
    }
  }

  SmsClient? get defaultSmsClient {
    return _default;
  }

  setSmsClient(String address) {
    SmsClient? smsClient;
    if (smsClients.containsKey(address)) {
      smsClient = smsClients[address];
    } else {
      smsClient = SmsClient(address);
      smsClients[address] = smsClient;
    }
  }

  SmsClient? setDefaultSmsClient(String address) {
    SmsClient? smsClient;
    if (smsClients.containsKey(address)) {
      smsClient = smsClients[address];
    } else {
      smsClient = SmsClient(address);
      smsClients[address] = smsClient;
    }
    _default = smsClient;

    return _default;
  }
}
