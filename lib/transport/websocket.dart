import 'dart:async';

import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/p2p/chain/chainmessagehandler.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import './condition_import/unsupport.dart'
    if (dart.library.html) './condition_import/web.dart'
    if (dart.library.io) './condition_import/desktop.dart' as websocket_connect;

enum SocketStatus {
  none,
  connecting,
  connected, // 已连接
  failed, // 失败
  closed, // 连接关闭
  reconnecting,
}

const String prefix = 'wss://';

class Websocket extends IWebClient {
  String? peerId;
  late String address;
  WebSocketChannel? channel;
  String? sessionId;
  SocketStatus _status = SocketStatus.closed;
  Duration pingInterval = const Duration(seconds: 30);
  Map<String, dynamic> headers = {};
  Timer? heartBeat; // 心跳定时器
  int heartTimes = 3000; // 心跳间隔(毫秒)
  int reconnectTimes = 5;
  Function(Websocket websocket, SocketStatus status)? onStatusChange;

  Websocket(this.address, Function() postConnected, {this.peerId}) {
    if (!address.startsWith(prefix)) {
      throw 'error wss address prefix';
    }
    this.postConnected = postConnected;
  }

  Future<void> connect() async {
    await close();
    try {
      channel = websocket_connect.websocketConnect(address,
          headers: headers, pingInterval: pingInterval);
    } catch (e) {
      logger.e('wss address:$address connect failure:$e');
    }
    if (channel == null) {
      logger.e('wss address:$address connect failure');
      return;
    }
    channel!.stream.listen((dynamic data) {
      onData(data);
    }, onError: onError, onDone: onDone, cancelOnError: false);
    status = SocketStatus.connecting;
    logger.i('wss address:$address websocket connecting');
  }

  onData(dynamic data) async {
    if (status != SocketStatus.connected) {
      logger.i('wss address:$address websocket from $status to connected');
      status = SocketStatus.connected;
      if (postConnected != null) {
        postConnected!();
      }
    }
    var msg = String.fromCharCodes(data);
    if (msg.startsWith('heartbeat:')) {
      var sessionId = msg.substring(10);
      if (this.sessionId != sessionId) {
        this.sessionId = sessionId;
        logger.w('wss sessionId has changed:$address:${this.sessionId}');
      }
    } else {
      await chainMessageHandler.receiveRaw(data, peerId, address);
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
    if (status != SocketStatus.closed) {
      status = SocketStatus.closed;
    }
    _reconnect();
  }

  onError(err) async {
    logger.e("wss address:$address websocket onError, $err");
    if (status != SocketStatus.failed) {
      status = SocketStatus.failed;
    }
    await _reconnect();
  }

  SocketStatus get status {
    return _status;
  }

  set status(SocketStatus status) {
    if (_status != status) {
      logger.w('websocket $address status changed from $_status to $status');
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

class WebsocketPool {
  var websockets = <String, Websocket>{};
  Websocket? _default;

  Map<String, List<Function(String address, SocketStatus status)>> fnsm = {};

  WebsocketPool() {
    connect();
  }

  registerStatusChanged(
      String address, Function(String address, SocketStatus status) fn) {
    List<Function(String address, SocketStatus status)>? fns = fnsm[address];
    if (fns == null) {
      fns = [];
      fnsm[address] = fns;
    }
    fns.add(fn);
  }

  unregisterStatusChanged(
      String address, Function(String address, SocketStatus status) fn) {
    List<Function(String address, SocketStatus status)>? fns = fnsm[address];
    if (fns == null) {
      return;
    }
    fns.remove(fn);
    if (fns.isEmpty) {
      fnsm.remove(address);
    }
  }

  onStatusChanged(Websocket websocket, SocketStatus status) {
    String address = websocket.address;
    List<Function(String address, SocketStatus status)>? fns = fnsm[address];
    if (fns != null) {
      for (var fn in fns) {
        fn(address, status);
      }
    }
  }

  ///初始化websocket的连接，尝试连接缺省socket
  Future<Websocket?> connect() async {
    var defaultPeerEndpoint = peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      var defaultAddress = defaultPeerEndpoint.wsConnectAddress;
      var defaultPeerId = defaultPeerEndpoint.peerId;
      Websocket? websocket;
      if (websockets.containsKey(defaultAddress)) {
        websocket = websockets[defaultAddress];
        _default = websocket;
        await websocket!.reconnect();
      } else {
        if (defaultAddress != null && defaultAddress.startsWith('ws')) {
          websocket = Websocket(defaultAddress, myselfPeerService.connect,
              peerId: defaultPeerId);
          await websocket.connect();
          if (websocket._status == SocketStatus.connected) {
            websockets[defaultAddress] = websocket;
            websocket.onStatusChange = onStatusChanged;
            _default = websocket;
          }
        }
      }
    }
    return _default;
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
        String? peerId;
        PeerEndpoint? peerEndpoint =
            peerEndpointController.find(address: address);
        if (peerEndpoint != null) {
          peerId = peerEndpoint.peerId;
        }
        websocket =
            Websocket(address, myselfPeerService.connect, peerId: peerId);
        websocket.onStatusChange = onStatusChanged;
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
