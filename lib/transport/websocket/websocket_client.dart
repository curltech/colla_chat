import 'dart:async';

import 'package:colla_chat/p2p/chain/chainmessagehandler.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:colla_chat/transport/websocket/universal_websocket.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:web_socket_client/web_socket_client.dart' as web_socket_client;

class WebsocketClient extends IWebClient {
  Key? key;
  String? peerId;
  late String address;
  web_socket_client.WebSocket? _client;
  StreamSubscription<web_socket_client.ConnectionState>?
      statusStreamSubscription;
  StreamSubscription<dynamic>? messageStreamSubscription;
  String? sessionId;

  // 连接没有完成时的消息缓存和缓存的锁
  final List<dynamic> messages = [];
  Lock lock = Lock();
  Map<String, dynamic> headers = {};
  StreamController<web_socket_client.ConnectionState> statusStreamController =
      StreamController<web_socket_client.ConnectionState>.broadcast();

  WebsocketClient(this.address, Function() postConnected, {this.peerId}) {
    key = UniqueKey();
    if (!address.startsWith(prefix)) {
      throw 'error wss address prefix';
    }
    this.postConnected = postConnected;
  }

  Future<bool> connect() async {
    logger.i('connect websocket wss address:$address');
    await close();
    try {
      const backoff = web_socket_client.ConstantBackoff(Duration(seconds: 1));
      _client =
          web_socket_client.WebSocket(Uri.parse(address), backoff: backoff);
      if (statusStreamSubscription != null) {
        await statusStreamSubscription!.cancel();
        statusStreamSubscription = null;
      }
      statusStreamSubscription = _client!.connection
          .listen((web_socket_client.ConnectionState connectionState) {
        statusStreamController.add(connectionState);
        if (connectionState is web_socket_client.Disconnected) {
          close();
        }
        if (connectionState is web_socket_client.Connected) {
          lock.synchronized(() {
            if (messages.isNotEmpty) {
              for (var message in messages) {
                if (_client != null) {
                  _client!.send(message);
                }
              }
              messages.clear();
            }
          });
        }
      });
      logger.i('wss address:$address websocket connected');

      if (messageStreamSubscription != null) {
        await messageStreamSubscription!.cancel();
        messageStreamSubscription = null;
      }
      messageStreamSubscription = _client!.messages.listen((dynamic data) {
        onData(data);
      }, onError: onError, onDone: onDone, cancelOnError: true);

      if (postConnected != null) {
        postConnected!();
      }
      if (_client == null) {
        logger.e('wss address:$address connect failure');
        return false;
      }

      return true;
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
        chainMessageHandler.websocketDataStreamController
            .add(WebsocketData(peerId!, address, sessionId!, data));
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

  web_socket_client.ConnectionState get status {
    return _client!.connection.state;
  }

  FutureOr<bool> sendMsg(dynamic data) async {
    if (_client != null &&
        _client!.connection.state is web_socket_client.Connected) {
      _client!.send(data);
      return true;
    } else {
      logger.e('status is not connected，cached');
      lock.synchronized(() {
        messages.add(data);
      });
      if (_client!.connection.state is web_socket_client.Disconnected) {
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
        messageStreamSubscription?.cancel();
        _client?.close();
      } catch (e) {
        logger.e('wss address:$address websocket channel!.sink.close error');
      }
      statusStreamSubscription = null;
      messageStreamSubscription = null;
      _client = null;
    }
  }
}
