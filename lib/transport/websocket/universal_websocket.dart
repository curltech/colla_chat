import 'dart:async';

import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/p2p/chain/chainmessagehandler.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/connectivity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:websocket_universal/websocket_universal.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityController with ChangeNotifier {
  late StreamSubscription<List<ConnectivityResult>> subscription;
  List<ConnectivityResult> connectivityResult = [];
  bool connected = false;

  ConnectivityController() {
    subscription =
        ConnectivityUtil.onConnectivityChanged(_onConnectivityChanged);
  }

  _onConnectivityChanged(List<ConnectivityResult> result) {
    if (result != connectivityResult) {
      connectivityResult = result;
      if (ConnectivityUtil.getMainResult(
              connectivityController.connectivityResult) !=
          ConnectivityResult.none) {
        connected = true;
      } else {
        connected = false;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    ConnectivityUtil.cancel(subscription);
    super.dispose();
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

class UniversalWebsocket extends IWebClient {
  Key? key;
  String? peerId;
  late String address;
  final connectionOptions = const SocketConnectionOptions(
    pingIntervalMs: 3000,
    timeoutConnectionMs: 4000,
    skipPingMessages: true,
    pingRestrictionForce: true,
  );
  DateTime? lastHeartBeatTime;
  Duration heartBeatTime = const Duration(milliseconds: 40000);
  Timer? heartBeatTimer;
  int reconnectTimes = 5;
  Duration reconnectTime = const Duration(milliseconds: 3000);
  Timer? reconnectTimer;
  IWebSocketHandler<List<int>, List<int>>? _client;
  StreamSubscription<ISocketState>? statusStreamSubscription;
  StreamSubscription<ISocketLogEvent>? logStreamSubscription;
  StreamSubscription<List<int>>? inMessageStreamSubscription;
  StreamSubscription<Object>? outMessageStreamSubscription;

  String? sessionId;

  // 连接没有完成时的消息缓存和缓存的锁
  final List<dynamic> messages = [];
  Lock lock = Lock();
  Map<String, dynamic> headers = {};

  StreamController<SocketStatus> statusStreamController =
      StreamController<SocketStatus>.broadcast();

  UniversalWebsocket(this.address, Function() postConnected, {this.peerId}) {
    key = UniqueKey();
    if (!address.startsWith(prefix)) {
      throw 'error wss address prefix';
    }
    this.postConnected = postConnected;
  }

  Future<bool> connect() async {
    logger.i('connect websocket wss address:$address');
    try {
      final IMessageProcessor<List<int>, List<int>> bytesSocketProcessor =
          SocketSimpleBytesProcessor();
      _client = IWebSocketHandler<List<int>, List<int>>.createClient(
        address,
        bytesSocketProcessor,
        connectionOptions: connectionOptions,
      );
      if (statusStreamSubscription != null) {
        await statusStreamSubscription!.cancel();
        statusStreamSubscription = null;
      }
      statusStreamSubscription =
          _client!.socketStateStream.listen((ISocketState state) {
        statusStreamController.add(state.status);
        if (state.status == SocketStatus.disconnected) {}
        if (state.status == SocketStatus.connected) {
          lock.synchronized(() {
            if (messages.isNotEmpty) {
              for (var message in messages) {
                if (_client != null) {
                  bool success = _client!.sendMessage(message);
                  if (!success) {
                    logger.e('send pool messages error');
                  }
                }
              }
              messages.clear();
            }
          });
          chatMessageService.sendUnsent();
        }
      });
      if (logStreamSubscription != null) {
        await logStreamSubscription!.cancel();
        logStreamSubscription = null;
      }
      logStreamSubscription = _client!.logEventStream.listen((debugEvent) {
        // logger.i('> debug event: ${debugEvent.socketLogEventType}'
        //     ' ping=${debugEvent.pingMs} ms. Debug message=${debugEvent.message}');
      });
      if (inMessageStreamSubscription != null) {
        await inMessageStreamSubscription!.cancel();
        inMessageStreamSubscription = null;
      }
      inMessageStreamSubscription =
          _client!.incomingMessagesStream.listen((data) {
        onData(data);
      }, onError: onError, onDone: onDone, cancelOnError: true);

      if (outMessageStreamSubscription != null) {
        await outMessageStreamSubscription!.cancel();
        outMessageStreamSubscription = null;
      }
      outMessageStreamSubscription =
          _client!.outgoingMessagesStream.listen((outMsg) {});

      final isConnected = await _client!.connect();
      if (!isConnected) {
        logger.e('wss address:$address connect failure');
        return false;
      }

      if (postConnected != null) {
        postConnected!();
      }
      initHeartBeat();

      return true;
    } catch (e) {
      logger.e('wss address:$address connect failure:$e');
    }

    return false;
  }

  onData(dynamic data) async {
    if (lastHeartBeatTime == null && _client != null) {
      statusStreamController.add(_client!.socketHandlerState.status);
    }
    lastHeartBeatTime = DateTime.now();
    // logger.i('wss address:$address websocket received data');
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
  onDone() async {
    logger.w("wss address:$address websocket onDone.");
    reconnect();
  }

  onError(err) async {
    logger.e("wss address:$address websocket onError, $err");
    reconnect();
  }

  SocketStatus? get status {
    return _client?.socketState.status;
  }

  /// 初始化心跳
  void initHeartBeat() {
    destroyHeartBeat();
    heartBeatTimer = Timer.periodic(heartBeatTime, (timer) {
      DateTime current = DateTime.now();
      if (lastHeartBeatTime == null ||
          current.difference(lastHeartBeatTime!).inMilliseconds >
              heartBeatTime.inMilliseconds) {
        logger.e("wss address:$address websocket no heartBeat");
        reconnect();
      }
    });
  }

  /// 销毁心跳
  void destroyHeartBeat() {
    if (heartBeatTimer != null) {
      heartBeatTimer!.cancel();
      heartBeatTimer = null;
    }
  }

  FutureOr<bool> sendMsg(dynamic data) async {
    if (connectivityController.connected) {
      if (_client != null && status == SocketStatus.connected) {
        bool success = _client!.sendMessage(data);
        if (success) {
          return true;
        }
      }
    }
    logger.e('status is not connected，cached');
    lock.synchronized(() {
      messages.add(data);
    });
    if (status == null || status == SocketStatus.disconnected) {
      connect();
    }
    return false;
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
    if (status != SocketStatus.disconnected) {
      if (_client != null) {
        try {
          await statusStreamSubscription?.cancel();
          await logStreamSubscription?.cancel();
          await inMessageStreamSubscription?.cancel();
          await outMessageStreamSubscription?.cancel();
          destroyHeartBeat();
          await _client?.disconnect('manual disconnect');
          _client?.close();
        } catch (e) {
          logger.e('wss address:$address websocket channel!.sink.close error');
        }

        statusStreamSubscription = null;
        logStreamSubscription = null;
        inMessageStreamSubscription = null;
        outMessageStreamSubscription = null;
        _client = null;
      }
    }
  }

  /// 重连机制，每隔一段时间连接一次，重复n次
  Future<void> reconnect() async {
    await close();
    if (reconnectTimer == null) {
      reconnectTimes = 5;
      reconnectTimer = Timer.periodic(reconnectTime, (timer) async {
        if (status == SocketStatus.connected) {
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
  var websockets = <String, UniversalWebsocket>{};
  UniversalWebsocket? _default;

  WebsocketPool() {
    connect();
  }

  UniversalWebsocket create(
    String address,
    dynamic Function() postConnected, {
    String? peerId,
  }) {
    return UniversalWebsocket(address, myselfPeerService.connect,
        peerId: peerId);
  }

  Future<UniversalWebsocket?> connect() async {
    return await lock.synchronized(() async {
      UniversalWebsocket? websocket = getDefault();
      if (websocket == null) {
        return await _connect();
      }

      return websocket;
    });
  }

  ///初始化缺省websocket的连接，尝试连接缺省socket
  Future<UniversalWebsocket?> _connect() async {
    var defaultPeerEndpoint = peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      var defaultAddress = defaultPeerEndpoint.wsConnectAddress;
      var defaultPeerId = defaultPeerEndpoint.peerId;
      UniversalWebsocket? websocket;
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
        if (websocket.status == null ||
            websocket.status == SocketStatus.disconnected) {
          await websocket.close();
          await websocket.connect();
          return _default;
        }
      }
      //如果不存在或者已经关闭，创建新的连接
      if (websocket == null) {
        if (defaultAddress != null && defaultAddress.startsWith('ws')) {
          websocket = UniversalWebsocket(
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
  UniversalWebsocket? get defaultWebsocket {
    return _default;
  }

  ///获取连接的缺省websocket
  UniversalWebsocket? getDefault() {
    if (_default != null &&
        (_default!.status == SocketStatus.connected ||
            _default!.status == SocketStatus.connecting)) {
      return _default;
    }
    return null;
  }

  Future<UniversalWebsocket?> get(String address,
      {bool isDefault = false}) async {
    return await lock.synchronized(() async {
      return _get(address, isDefault: isDefault);
    });
  }

  ///获取或者连接指定地址的websocket的连接，并可以根据参数是否设置为缺省
  Future<UniversalWebsocket?> _get(String address,
      {bool isDefault = false}) async {
    UniversalWebsocket? websocket;
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
      if (websocket.status == null ||
          websocket.status == SocketStatus.disconnected) {
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
        websocket = UniversalWebsocket(address, myselfPeerService.connect,
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

  close(String address) async {
    await lock.synchronized(() async {
      _close(address);
    });
  }

  _close(String address) {
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
