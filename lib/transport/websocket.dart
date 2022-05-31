import 'dart:convert';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../app.dart';
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
      channel = HtmlWebSocketChannel.connect(Uri.parse(address));
    } else {
      channel = IOWebSocketChannel.connect(Uri.parse(address),
          headers: headers, pingInterval: pingInterval);
    }
    _status = true;
  }

  @override
  register(String name, Function func) {
    // 监听消息，如果有消息到来，就打印出来
    channel.stream.listen((message) {
      func(message);
    }, onError: onError, onDone: onDone, cancelOnError: false);
    _status = true;
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
  static WebsocketPool instance = WebsocketPool();
  static bool initStatus = false;

  /// 初始化连接池，设置缺省websocketclient，返回连接池
  static Future<WebsocketPool> getInstance() async {
    if (!initStatus) {
      var appParams = await AppParams.instance;
      var connectAddress = appParams.wsConnectAddress;
      int i = 0;
      if (connectAddress.isNotEmpty) {
        for (var addr in connectAddress) {
          if (addr.startsWith('ws')) {
            var websocket = Websocket(addr);
            instance.websockets[addr] = websocket;
            if (i == 0 && instance._default == null) {
              instance._default = websocket;
            }
          }
        }
      }
      initStatus = true;
    }
    return instance;
  }

  var websockets = <String, Websocket>{};
  Websocket? _default;

  WebsocketPool() {}

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
