import 'dart:async';
import 'dart:io';

import 'package:colla_chat/p2p/chain/chainmessagehandler.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:colla_chat/transport/websocket/universal_websocket.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum SocketStatus {
  none,
  connecting,
  connected, // 已连接
  disconnected, // 连接关闭
  disconnecting,
  reconnecting,
}

class Websocket extends IWebSocket {
  Key? key;
  String? peerId;
  late String address;
  WebSocketChannel? channel;

  // web_socket_client.WebSocket? _client;
  StreamSubscription<dynamic>? streamSubscription;
  String? sessionId;
  SocketStatus _status = SocketStatus.disconnected;

  // 连接没有完成时的消息缓存和缓存的锁
  final List<dynamic> messages = [];
  Lock lock = Lock();
  Map<String, dynamic> headers = {};
  DateTime? lastHeartBeatTime;
  Duration heartBeatTime = const Duration(milliseconds: 40000);
  Timer? heartBeat;
  int reconnectTimes = 5;
  Duration reconnectTime = const Duration(milliseconds: 3000);
  Timer? reconnectTimer;
  StreamController<SocketStatus> statusStreamController =
      StreamController<SocketStatus>.broadcast();

  Websocket(this.address, Function() postConnected, {this.peerId}) {
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
      channel = WebSocketChannel.connect(Uri.parse(address));
    } catch (e) {
      logger.e('wss address:$address connect failure:$e');
    }
    if (channel == null) {
      logger.e('wss address:$address connect failure');
      return false;
    }
    try {
      await channel!.ready;
      status = SocketStatus.connected;
      logger.i('wss address:$address websocket connected');

      if (streamSubscription != null) {
        await streamSubscription!.cancel();
        streamSubscription = null;
      }
      streamSubscription = channel!.stream.listen((dynamic data) {
        onData(data);
      }, onError: onError, onDone: onDone, cancelOnError: true);

      initHeartBeat();

      if (postConnected != null) {
        postConnected!();
      }

      return true;
    } on SocketException catch (e) {
      logger.e('wss address:$address websocket socketException:$e');
    } on WebSocketChannelException catch (e) {
      logger.e('wss address:$address websocket webSocketChannelException:$e');
    }

    return false;
  }

  onData(dynamic data) async {
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
  onDone() async {
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

  onError(err) async {
    logger.e("wss address:$address websocket onError, $err");
    if (status != SocketStatus.disconnecting) {
      status = SocketStatus.disconnecting;
    }
    await reconnect();
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
    if (channel != null && _status == SocketStatus.connected) {
      channel!.sink.add(data);
      return true;
    } else {
      logger.e('status is not connected，cached');
      lock.synchronized(() {
        messages.add(data);
      });
      if (_status == SocketStatus.disconnected) {
        return false;
      }
      if (_status != SocketStatus.connecting &&
          _status != SocketStatus.reconnecting) {
        await reconnect();
      }
      return false;
    }
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
