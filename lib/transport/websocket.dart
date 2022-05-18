import 'dart:convert';

import 'package:colla_chat/transport/webclient.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';
import '../tool/util.dart';

class Websocket implements IWebClient {
  String prefix = 'wss://';
  String? address;
  IOWebSocketChannel? channel;
  bool _status = false;
  String? heartbeatTimer;

  Websocket(String addr) {
    var pos = addr.indexOf(prefix);
    if (pos == 0) {
      addr = addr.substring(6);
    }
    while (addr.endsWith('/')) {
      addr = addr.substring(0, addr.length - 1);
    }
    address = addr;
    Map<String, dynamic> headers = {};
    var pingInterval = const Duration(seconds: 10);
    channel = IOWebSocketChannel.connect(addr,
        headers: headers, pingInterval: pingInterval);
  }

  @override
  register(String name, Function func) {
    // 监听消息，如果有消息到来，就打印出来
    channel?.stream.listen((message) {
      if (func != null) {
        func(message);
      } else {
        print(message);
      }
    }, onError: (error) {}, onDone: () {}, cancelOnError: false);
    _status = true;
  }

  sendMsg(dynamic data) {
    channel?.sink.add(data);
  }

  @override
  send(String url, dynamic data) {
    var message = {url: url, data: data};
    var json = jsonEncode(message);
    sendMsg(json);
  }

  @override
  dynamic get(String url) {
    return send(url, {});
  }

  bool get status {
    return _status;
  }

  void close() {
    channel?.sink.close();
    _status = false;
  }

  reconnect() {}
}

class WebsocketPool {
  var websockets = <String, Websocket>{};
  Websocket? _default;

  WebsocketPool() {
    var connectAddress = config.appParams.wsConnectAddress;
    int i = 0;
    for (var addr in connectAddress) {
      if (addr.startsWith('ws')) {
        var websocket = Websocket(addr);
        websockets[addr] = websocket;
        if (i == 0 && _default == null) {
          _default = websocket;
        }
      }
    }
  }

  Websocket? get(String address) {
    if (websockets.containsKey(address)) {
      return websockets[address];
    } else {
      var websocket = Websocket(address);
      websocket.reconnect();
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

  setDefalutWebsocket(String address) {
    Websocket? websocket;
    if (this.websockets.containsKey(address)) {
      websocket = websockets[address];
    } else {
      websocket = Websocket(address);
      websockets[address] = websocket;
    }
    _default = websocket;
  }
}

final websocketPool = WebsocketPool();
