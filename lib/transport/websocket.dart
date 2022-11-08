import 'dart:async';

import 'package:colla_chat/constant/address.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import './condition_import/unsupport.dart'
    if (dart.library.html) './condition_import/web.dart'
    if (dart.library.io) './condition_import/desktop.dart' as websocket_connect;
import '../p2p/chain/chainmessagehandler.dart';

enum SocketStatus {
  connected, // 已连接
  failed, // 失败
  closed, // 连接关闭
  reconnecting,
}

class Websocket implements IWebClient {
  String prefix = 'wss://';
  late String address;
  WebSocketChannel? channel;
  SocketStatus _status = SocketStatus.closed;
  Duration pingInterval = const Duration(seconds: 30);
  Map<String, dynamic> headers = {};
  Timer? heartBeat; // 心跳定时器
  int heartTimes = 3000; // 心跳间隔(毫秒)
  int reconnectTimes = 5;
  Function(Websocket websocket, SocketStatus status)? onStatusChange;

  Websocket(String addr) {
    if (!addr.startsWith(prefix)) {
      throw 'error wss address prefix';
    }
    address = addr;
  }

  Future<void> connect() async {
    await close();
    channel = websocket_connect.websocketConnect(address,
        headers: headers, pingInterval: pingInterval);
    if (channel == null) {
      logger.e('wss address:$address connect failure');
      return;
    }
    register('', onData);
    //initHeartBeat();
    status = SocketStatus.connected;
    reconnectTimes = 5;
    //logger.i('wss address:$address websocket connected');
  }

  @override
  register(String name, Function func) {
    if (channel != null) {
      // 监听消息，如果有消息到来，就打印出来
      channel!.stream.listen((dynamic data) {
        func(data);
      }, onError: onError, onDone: onDone, cancelOnError: false);
    }
  }

  onData(dynamic data) async {
    var msg = String.fromCharCodes(data);
    if (msg == 'heartbeat') {
      //logger.i('wss address:$address receive heartbeat message');
    } else {
      //logger.w(msg);
      var response = await chainMessageHandler.receiveRaw(data, '', '');
      if (response != null) {
        sendMsg(response);
      }
    }
  }

  ///连接被关闭或出错的时候重连
  onDone() async {
    int? closeCode;
    String? closeReason;
    if (channel != null) {
      closeCode = channel!.closeCode;
      closeReason = channel!.closeReason;
    }
    logger.w(
        "wss address:$address websocket onDone. closeCode:$closeCode;closeReason:$closeReason");
    status = SocketStatus.closed;
    reconnect();
  }

  onError(err) async {
    logger.e("wss address:$address websocket onError, $err");
    status = SocketStatus.failed;
    await reconnect();
  }

  SocketStatus get status {
    return _status;
  }

  set status(SocketStatus status) {
    if (_status != status) {
      _status = status;
      if (onStatusChange != null) {
        onStatusChange!(this, status);
      }
    }
  }

  /// 初始化心跳
  void initHeartBeat() {
    destroyHeartBeat();
    heartBeat = Timer.periodic(Duration(milliseconds: heartTimes), (timer) {
      sentHeart();
    });
  }

  /// 心跳
  void sentHeart() {
    sendMsg('heartbeat');
  }

  /// 销毁心跳
  void destroyHeartBeat() {
    if (heartBeat != null) {
      heartBeat!.cancel();
      heartBeat = null;
    }
  }

  sendMsg(dynamic data) {
    if (channel != null && _status == SocketStatus.connected) {
      channel!.sink.add(data);
    } else {
      logger.e('status is not connected');
      reconnect().then((value) {
        if (channel != null && _status == SocketStatus.connected) {
          sendMsg(data);
        }
      });
    }
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

  Future<void> close() async {
    if (_status != SocketStatus.closed) {
      if (channel != null) {
        try {
          var sink = channel!.sink;
          sink.close();
        } catch (e) {
          logger.e('wss address:$address websocket channel!.sink.close error');
        }
        channel = null;
        destroyHeartBeat();
        status = SocketStatus.closed;
      }
    }
  }

  /// 重连机制
  Future<void> reconnect() async {
    Timer.periodic(Duration(milliseconds: heartTimes), (timer) async {
      if (reconnectTimes <= 0 || _status == SocketStatus.connected) {
        timer.cancel();
        return;
      }
      reconnectTimes--;
      status = SocketStatus.reconnecting;
      logger.i('wss address:$address $reconnectTimes websocket reconnecting');
      await connect();
    });
  }
}

class WebsocketPool with ChangeNotifier {
  var websockets = <String, Websocket>{};
  Websocket? _default;

  WebsocketPool() {
    var nodeAddress = appDataProvider.nodeAddress;
    if (nodeAddress.isNotEmpty) {
      NodeAddress? defaultNodeAddress = nodeAddress[NodeAddress.defaultName];
      if (defaultNodeAddress != null) {
        var defaultAddress = defaultNodeAddress.wsConnectAddress;
        if (defaultAddress != null && defaultAddress.startsWith('ws')) {
          var websocket = Websocket(defaultAddress);
          websocket.connect().then((value) {
            if (websocket._status == SocketStatus.connected) {
              websockets[defaultAddress] = websocket;
              websocket.onStatusChange = onStatusChange;
              _default = websocket;
            }
          });
        }
      }
    }
  }

  onStatusChange(Websocket websocket, SocketStatus status) {
    notifyListeners();
  }

  Websocket? getDefault() {
    return _default;
  }

  Future<Websocket?> get(String address, {bool isDefault = false}) async {
    Websocket? websocket;
    if (websockets.containsKey(address)) {
      websocket = websockets[address];
    } else {
      if (address.startsWith('ws')) {
        websocket = Websocket(address);
        websocket.onStatusChange = onStatusChange;
        await websocket.connect();
        if (websocket._status == SocketStatus.connected) {
          websockets[address] = websocket;
        } else {
          websocket = null;
        }
      }
    }
    if (isDefault && websocket != null) {
      _default = websocket;
    }
    return websocket;
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
}

final WebsocketPool websocketPool = WebsocketPool();
