import 'package:colla_chat/platform.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import './condition_import/unsupport.dart'
    if (dart.library.html) './condition_import/web.dart'
    if (dart.library.io) './condition_import/desktop.dart' as websocket_connect;

import '../p2p/chain/chainmessagehandler.dart';
import '../provider/app_data.dart';
import '../tool/util.dart';

class Websocket implements IWebClient {
  String prefix = 'wss://';
  late String address;
  late WebSocketChannel channel;
  bool _status = false;
  Duration pingInterval = const Duration(seconds: 10);
  Map<String, dynamic> headers = {};
  String? heartbeatTimer;

  Websocket(String addr) {
    if (!addr.startsWith(prefix)) {
      throw 'error wss address prefix';
    }
    address = addr;
    connect();
  }

  connect() async {
    if (PlatformParams.instance.web) {
      channel = websocket_connect.websocketConnect(address,
          headers: headers, pingInterval: pingInterval);
    }
    register('', onData);
    _status = true;
  }

  @override
  register(String name, Function func) {
    // 监听消息，如果有消息到来，就打印出来
    channel.stream.listen((dynamic data) {
      func(data);
    }, onError: onError, onDone: onDone, cancelOnError: false);
    _status = true;
  }

  onData(dynamic data) async {
    var msg = String.fromCharCodes(data);
    if (msg == 'heartbeat') {
      logger.i('receive heartbeat message');
    } else {
      logger.w(msg);
      var response = await chainMessageHandler.receiveRaw(data, '', '');
      sendMsg(response);
    }
  }

  onDone() async {
    logger.i("websocket onDone");
    await reconnect();
  }

  onError(err) async {
    logger.e("websocket onError, ${err}");
    await reconnect();
  }

  sendMsg(dynamic data) {
    channel.sink.add(data);
  }

  @override
  send(String url, dynamic data) {
    var message = {url: url, data: data};
    var json = JsonUtil.toJsonString(message);
    sendMsg(json);
  }

  @override
  dynamic get(String url) {
    return send(url, {});
  }

  bool get status {
    return _status;
  }

  Future<void> close() async {
    if (_status) {
      await channel.sink.close();
      _status = false;
    }
  }

  reconnect() async {
    await close();
    connect();
  }
}

class WebsocketPool {
  static final WebsocketPool _instance = WebsocketPool();
  static bool initStatus = false;

  /// 初始化连接池，设置缺省websocketclient，返回连接池
  static WebsocketPool get instance {
    if (!initStatus) {
      var appParams = AppDataProvider.instance;
      var nodeAddress = appParams.nodeAddress;
      if (nodeAddress.isNotEmpty) {
        for (var address in nodeAddress.entries) {
          var name = address.key;
          var wsConnectAddress = address.value.wsConnectAddress;
          if (wsConnectAddress != null && wsConnectAddress.startsWith('ws')) {
            var websocket = Websocket(wsConnectAddress);
            _instance.websockets[wsConnectAddress] = websocket;
            if (name == NodeAddress.defaultName) {
              _instance._default = websocket;
            }
          }
        }
      }
      initStatus = true;
    }
    return _instance;
  }

  var websockets = <String, Websocket>{};
  Websocket? _default;

  WebsocketPool();

  Websocket? get(String address) {
    if (websockets.containsKey(address)) {
      return websockets[address];
    } else {
      var websocket = Websocket(address);
      websockets[address] = websocket;

      return websocket;
    }
  }

  close(String address) {
    if (websockets.containsKey(address)) {
      var websocket = websockets[address];
      if (websocket != null) {
        websocket.close();
      }
      websockets.remove(address);
    }
  }

  Websocket? get defaultWebsocket {
    return _default;
  }

  setWebsocket(String address) {
    Websocket? websocket;
    if (websockets.containsKey(address)) {
      websocket = websockets[address];
    } else {
      websocket = Websocket(address);
      websockets[address] = websocket;
    }
  }

  Websocket? setDefaultWebsocket(String address) {
    Websocket? websocket;
    if (websockets.containsKey(address)) {
      websocket = websockets[address];
    } else {
      websocket = Websocket(address);
      websockets[address] = websocket;
    }
    _default = websocket;

    return _default;
  }
}
