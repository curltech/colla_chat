import 'dart:async';

import 'package:colla_chat/p2p/chain/chainmessagehandler.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:colla_chat/transport/websocket/common_websocket.dart'
    as common_websocket;
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:websocket_universal/websocket_universal.dart';

class UniversalWebsocket extends IWebClient {
  Key? key;
  String? peerId;
  late String address;
  final connectionOptions = const SocketConnectionOptions(
    pingIntervalMs: 3000,
    timeoutConnectionMs: 4000,
    skipPingMessages: false,
  );
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

  //Function(Websocket websocket, SocketStatus status)? onStatusChange;

  UniversalWebsocket(this.address, Function() postConnected, {this.peerId}) {
    key = UniqueKey();
    if (!address.startsWith(common_websocket.prefix)) {
      throw 'error wss address prefix';
    }
    this.postConnected = postConnected;
  }

  Future<bool> connect() async {
    logger.i('connect websocket wss address:$address');
    await close();
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
        if (state.status == SocketStatus.disconnected) {
          close();
        }
        if (state.status == SocketStatus.connected) {
          lock.synchronized(() {
            if (messages.isNotEmpty) {
              for (var message in messages) {
                if (_client != null) {
                  _client!.sendMessage(message);
                }
              }
              messages.clear();
            }
          });
        }
      });
      if (logStreamSubscription != null) {
        await logStreamSubscription!.cancel();
        logStreamSubscription = null;
      }
      logStreamSubscription = _client!.logEventStream.listen((debugEvent) {
        logger.i('> debug event: ${debugEvent.socketLogEventType}'
            ' ping=${debugEvent.pingMs} ms. Debug message=${debugEvent.message}');
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
          _client!.outgoingMessagesStream.listen((inMsg) {
        // ignore: avoid_print
        logger.i('> webSocket sent bytes message to   server: "$inMsg"');
      });

      final isBytesSocketConnected = await _client!.connect();
      if (!isBytesSocketConnected) {
        logger.e('wss address:$address connect failure');
        return false;
      }

      if (postConnected != null) {
        postConnected!();
      }
    } catch (e) {
      logger.e('wss address:$address connect failure:$e');
    }

    return false;
  }

  onData(dynamic data) async {
    logger.i('wss address:$address websocket from $status to connected');
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
        chainMessageHandler.websocketDataStreamController.add(
            common_websocket.WebsocketData(peerId!, address, sessionId!, data));
      }
    }
  }

  ///连接被关闭或出错的时候重连
  onDone() async {
    logger.w("wss address:$address websocket onDone.");
  }

  onError(err) async {
    logger.e("wss address:$address websocket onError, $err");
  }

  SocketStatus get status {
    return _client!.socketState.status;
  }

  FutureOr<bool> sendMsg(dynamic data) async {
    if (_client != null && status == SocketStatus.connected) {
      _client!.sendMessage(data);
      return true;
    } else {
      logger.e('status is not connected，cached');
      lock.synchronized(() {
        messages.add(data);
      });
      if (status == SocketStatus.disconnected) {
        connect();
      }
      return false;
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
    if (_client != null) {
      try {
        statusStreamSubscription?.cancel();
        logStreamSubscription?.cancel();
        inMessageStreamSubscription?.cancel();
        outMessageStreamSubscription?.cancel();
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
