import 'dart:async';

import 'package:colla_chat/constant/address.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import './condition_import/unsupport.dart'
    if (dart.library.html) './condition_import/web.dart'
    if (dart.library.io) './condition_import/desktop.dart' as websocket_connect;
import '../p2p/chain/chainmessagehandler.dart';

enum SocketStatus {
  created,
  connected, // 已连接
  failed, // 失败
  closed, // 连接关闭
  reconnecting,
}

class Websocket extends IWebClient {
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

  Websocket(this.address, Function() postConnected) {
    if (!address.startsWith(prefix)) {
      throw 'error wss address prefix';
    }
    this.postConnected = postConnected;
  }

  Future<void> connect() async {
    await close();
    channel = websocket_connect.websocketConnect(address,
        headers: headers, pingInterval: pingInterval);
    if (channel == null) {
      logger.e('wss address:$address connect failure');
      return;
    }
    channel!.stream.listen((dynamic data) {
      onData(data);
    }, onError: onError, onDone: onDone, cancelOnError: false);
    status = SocketStatus.created;
    //logger.i('wss address:$address websocket connected');
    // Future.delayed(const Duration(milliseconds: 500), () {
    //   if (postConnected != null && status == SocketStatus.connected) {
    //     postConnected!();
    //   }
    // });
  }

  onData(dynamic data) async {
    if (status != SocketStatus.connected) {
      status = SocketStatus.connected;
      if (postConnected != null) {
        postConnected!();
      }
    }
    var msg = String.fromCharCodes(data);
    if (msg == 'heartbeat') {
      //logger.i('wss address:$address receive heartbeat message');
    } else {
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
    _reconnect();
  }

  onError(err) async {
    logger.e("wss address:$address websocket onError, $err");
    status = SocketStatus.failed;
    await _reconnect();
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

  FutureOr<bool> sendMsg(dynamic data) async {
    if (channel != null && _status == SocketStatus.connected) {
      channel!.sink.add(data);
      return true;
    } else {
      logger.e('status is not connected');
      await reconnect();
      if (channel != null && _status == SocketStatus.connected) {
        return sendMsg(data);
      } else {
        return false;
      }
    }
  }

  @override
  FutureOr<bool> send(String url, dynamic data) async {
    var message = {url: url, data: data};
    var json = JsonUtil.toJsonString(message);

    return sendMsg(json);
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

  Future<void> reconnect() async {
    if (_status == SocketStatus.closed || _status == SocketStatus.failed) {
      reconnectTimes = 5;
      _reconnect();
    }
  }

  /// 重连机制
  Future<void> _reconnect() async {
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
          var websocket =
              Websocket(defaultAddress, myselfPeerService.connect);
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
        websocket = Websocket(address, myselfPeerService.connect);
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
