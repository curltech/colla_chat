import 'dart:async';
import 'dart:io';

import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/p2p/chain/chainmessagehandler.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/connectivity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:synchronized/synchronized.dart';
import 'package:web_socket_channel/web_socket_channel.dart'
    as web_socket_channel;
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityController {
  late StreamSubscription<List<ConnectivityResult>> subscription;
  final RxList<ConnectivityResult> connectivityResult =
      <ConnectivityResult>[].obs;
  final RxBool connected = false.obs;

  ConnectivityController() {
    subscription =
        ConnectivityUtil.onConnectivityChanged(_onConnectivityChanged);
  }

  void _onConnectivityChanged(List<ConnectivityResult> result) {
    connectivityResult(result);
    if (ConnectivityUtil.getMainResult(
            connectivityController.connectivityResult) !=
        ConnectivityResult.none) {
      connected(true);
    } else {
      connected(false);
    }
  }

  void dispose() {
    ConnectivityUtil.cancel(subscription);
  }
}

ConnectivityController connectivityController = ConnectivityController();

const String prefix = 'wss://';

/// websocket接收到的原始数据
class WebsocketData {
  String peerId;
  String address;
  String sessionId;
  dynamic data;

  WebsocketData(this.peerId, this.address, this.sessionId, this.data);
}

enum SocketStatus {
  none,
  connecting,
  connected, // 已连接
  disconnected, // 连接关闭
  disconnecting,
  reconnecting,
}

class WebSocketChannel extends IWebSocket {
  Key? key;
  String? peerId;
  late String address;
  web_socket_channel.WebSocketChannel? channel;
  SocketStatus _status = SocketStatus.disconnected;
  DateTime? lastHeartBeatTime;
  Duration heartBeatTime = const Duration(milliseconds: 40000);
  Timer? heartBeat;
  int reconnectTimes = 5;
  Duration reconnectTime = const Duration(milliseconds: 3000);
  Timer? reconnectTimer;
  String? sessionId;

  // 连接没有完成时的消息缓存和缓存的锁
  final List<dynamic> messages = [];
  Lock lock = Lock();
  Map<String, dynamic> headers = {};
  StreamSubscription<dynamic>? dataStreamSubscription;
  StreamController<SocketStatus> statusStreamController =
      StreamController<SocketStatus>.broadcast();

  WebSocketChannel(this.address, Function() postConnected, {this.peerId}) {
    key = UniqueKey();
    if (!address.startsWith(prefix)) {
      throw 'error wss address prefix';
    }
    this.postConnected = postConnected;
  }

  @override
  Future<bool> connect() async {
    status = SocketStatus.connecting;
    logger.i('connect websocket wss address:$address');
    try {
      channel = web_socket_channel.WebSocketChannel.connect(Uri.parse(address));
    } catch (e) {
      logger.e('wss address:$address connect failure:$e');
    }
    if (channel == null) {
      logger.e('wss address:$address connect failure');
      status = SocketStatus.disconnected;
      return false;
    }
    try {
      await channel!.ready;
      status = SocketStatus.connected;
      logger.i('wss address:$address websocket connected');

      if (dataStreamSubscription != null) {
        await dataStreamSubscription!.cancel();
        dataStreamSubscription = null;
      }
      dataStreamSubscription = channel!.stream.listen((dynamic data) {
        onData(data);
      }, onError: onError, onDone: onDone, cancelOnError: true);

      initHeartBeat();

      if (postConnected != null) {
        postConnected!();
      }

      return true;
    } on SocketException catch (e) {
      status = SocketStatus.disconnected;
      logger.e('wss address:$address websocket socketException:$e');
    } on web_socket_channel.WebSocketChannelException catch (e) {
      status = SocketStatus.disconnected;
      logger.e('wss address:$address websocket webSocketChannelException:$e');
    }

    return false;
  }

  Future<void> onData(dynamic data) async {
    if (lastHeartBeatTime == null && channel != null) {
      statusStreamController.add(_status);
    }
    lastHeartBeatTime = DateTime.now();
    if (status != SocketStatus.connected) {
      logger.i('wss address:$address websocket from $status to connected');
      status = SocketStatus.connected;
    }
    var msg = String.fromCharCodes(data);
    if (msg.startsWith('heartbeat:')) {
      var sessionId = msg.substring(10);
      if (this.sessionId != sessionId) {
        logger.w(
            'wss sessionId has changed:$address from ${this.sessionId} to $sessionId');
        this.sessionId = sessionId;
      }
    } else {
      if (peerId != null && sessionId != null) {
        chainMessageHandler.websocketDataStreamController
            .add(WebsocketData(peerId!, address, sessionId!, data));
      }
    }
  }

  ///连接被关闭或出错的时候重连
  Future<void> onDone() async {
    int? closeCode;
    String? closeReason;
    if (channel != null) {
      closeCode = channel!.closeCode;
      closeReason = channel!.closeReason;
    }
    logger.w(
        "wss address:$address websocket onDone. closeCode:$closeCode;closeReason:$closeReason");
    if (status != SocketStatus.disconnected) {
      status = SocketStatus.disconnected;
    }
    reconnect();
  }

  Future<void> onError(err) async {
    logger.e("wss address:$address websocket onError, $err");
    if (status != SocketStatus.disconnecting) {
      status = SocketStatus.disconnecting;
    }
    reconnect();
  }

  @override
  SocketStatus get status {
    return _status;
  }

  set status(SocketStatus status) {
    if (_status != status) {
      logger.w('websocket $address status changed from $_status to $status');
      _status = status;
      statusStreamController.add(status);
      //当状态变为连接的时候，发送缓存的消息
      if (status == SocketStatus.connected) {
        lock.synchronized(() {
          if (messages.isNotEmpty) {
            for (var message in messages) {
              if (channel != null) {
                channel!.sink.add(message);
              }
            }
            messages.clear();
          }
        });
      }
    }
  }

  /// 初始化心跳
  void initHeartBeat() {
    destroyHeartBeat();
    heartBeat = Timer.periodic(heartBeatTime, (timer) {
      DateTime current = DateTime.now();
      if (lastHeartBeatTime == null ||
          current.difference(lastHeartBeatTime!).inMilliseconds >
              heartBeatTime.inMilliseconds) {
        reconnect();
      }
    });
  }

  /// 销毁心跳
  void destroyHeartBeat() {
    if (heartBeat != null) {
      heartBeat!.cancel();
      heartBeat = null;
    }
  }

  @override
  FutureOr<bool> sendMsg(dynamic data) async {
    if (connectivityController.connected.value) {
      if (channel != null && _status == SocketStatus.connected) {
        channel!.sink.add(data);
        return true;
      }
    }
    logger.e('status is not connected，cached');
    lock.synchronized(() {
      messages.add(data);
    });
    if (_status == SocketStatus.disconnected) {
      await reconnect();
    }
    if (_status != SocketStatus.connecting &&
        _status != SocketStatus.reconnecting) {
      await reconnect();
    }
    return false;
  }

  @override
  FutureOr<bool> send(String url, dynamic data) async {
    var message = {url: url, data: data};
    var json = JsonUtil.toJsonString(message);

    return await sendMsg(json);
  }

  @override
  dynamic get(String url) async {
    return await send(url, {});
  }

  @override
  Future<void> close() async {
    sessionId = null;
    if (_status != SocketStatus.disconnected) {
      if (channel != null) {
        try {
          var sink = channel!.sink;
          await sink.close();
        } catch (e) {
          logger.e('wss address:$address websocket channel!.sink.close error');
        }
        channel = null;
        destroyHeartBeat();
        status = SocketStatus.disconnected;
      }
    }
  }

  /// 重连机制，每隔一段时间连接一次，重复n次
  Future<void> reconnect() async {
    await close();
    if (reconnectTimer == null) {
      status = SocketStatus.reconnecting;
      reconnectTimes = 5;
      reconnectTimer = Timer.periodic(reconnectTime, (timer) async {
        if (_status == SocketStatus.connected) {
          reconnectTimer?.cancel();
          reconnectTimer = null;
          reconnectTimes = 0;
          return;
        }
        if (reconnectTimes <= 0) {
          reconnectTimer?.cancel();
          reconnectTimer = null;
          reconnectTimes = 0;
          return;
        }
        reconnectTimes--;
        logger.i('wss address:$address $reconnectTimes websocket reconnecting');
        await connect();
      });
    }
  }
}

class WebsocketPool {
  Lock lock = Lock();
  var websockets = <String, WebSocketChannel>{};
  WebSocketChannel? _default;

  WebsocketPool() {
    connect();
  }

  WebSocketChannel create(
    String address,
    dynamic Function() postConnected, {
    String? peerId,
  }) {
    return WebSocketChannel(address, myselfPeerService.connect, peerId: peerId);
  }

  Future<WebSocketChannel?> connect() async {
    return await lock.synchronized(() async {
      WebSocketChannel? websocket = getDefault();
      if (websocket == null) {
        return await _connect();
      }

      return websocket;
    });
  }

  ///初始化缺省websocket的连接，尝试连接缺省socket
  Future<WebSocketChannel?> _connect() async {
    var defaultPeerEndpoint = peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      var defaultAddress = defaultPeerEndpoint.wsConnectAddress;
      var defaultPeerId = defaultPeerEndpoint.peerId;
      WebSocketChannel? websocket;
      //如果已经存在，且是连接或者在连接中，直接返回
      if (websockets.containsKey(defaultAddress)) {
        websocket = websockets[defaultAddress];
        logger.w(
            'wss defaultAddress:$defaultAddress websocket is exist:${websocket!.status}');
        _default = websocket;
        if (websocket.status == SocketStatus.connected ||
            websocket.status == SocketStatus.connecting) {
          return _default;
        }
        //如果已经关闭，从池中移除
        if (websocket.status == SocketStatus.disconnected) {
          await websocket.close();
          await websocket.connect();
          return _default;
        }
      }
      //如果不存在或者已经关闭，创建新的连接
      if (websocket == null) {
        if (defaultAddress != null && defaultAddress.startsWith('ws')) {
          websocket = WebSocketChannel(
              defaultAddress, myselfPeerService.connect,
              peerId: defaultPeerId);
          logger.i('websocket $defaultAddress instance is created!');
          bool success = await websocket.connect();
          if (success) {
            websockets[defaultAddress] = websocket;
            _default = websocket;
          }
        }
      }
    } else {
      logger.e('defaultPeerEndpoint is not exist');
    }
    return _default;
  }

  ///获取缺省websocket
  WebSocketChannel? get defaultWebsocket {
    return _default;
  }

  ///获取连接的缺省websocket
  WebSocketChannel? getDefault() {
    if (_default != null &&
        (_default!.status == SocketStatus.connected ||
            _default!.status == SocketStatus.connecting)) {
      return _default;
    }
    return null;
  }

  Future<WebSocketChannel?> get(String address,
      {bool isDefault = false}) async {
    return await lock.synchronized(() async {
      return _get(address, isDefault: isDefault);
    });
  }

  ///获取或者连接指定地址的websocket的连接，并可以根据参数是否设置为缺省
  Future<WebSocketChannel?> _get(String address,
      {bool isDefault = false}) async {
    WebSocketChannel? websocket;
    if (websockets.containsKey(address)) {
      websocket = websockets[address];
      // logger.i('wss address:$address websocket is exist:${websocket!.status}');
      if (websocket!.status == SocketStatus.connected ||
          websocket.status == SocketStatus.connecting) {
        if (isDefault) {
          _default = websocket;
        }
        return websocket;
      }
      //如果已经关闭，从池中移除
      if (websocket.status == SocketStatus.disconnected) {
        await websocket.close();
        await websocket.connect();

        return websocket;
      }
    }
    if (websocket == null) {
      if (address.startsWith('ws')) {
        String? peerId;
        PeerEndpoint? peerEndpoint =
            peerEndpointController.find(address: address);
        if (peerEndpoint != null) {
          peerId = peerEndpoint.peerId;
        }
        websocket = WebSocketChannel(address, myselfPeerService.connect,
            peerId: peerId);
        await websocket.connect();
        websockets[address] = websocket;
        if (isDefault) {
          _default = websocket;
        }
      }
    }

    return websocket;
  }

  Future<void> close(String address) async {
    await lock.synchronized(() async {
      _close(address);
    });
  }

  void _close(String address) {
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
