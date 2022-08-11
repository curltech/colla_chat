import 'dart:async';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webclient.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import './condition_import/unsupport.dart'
    if (dart.library.html) './condition_import/web.dart'
    if (dart.library.io) './condition_import/desktop.dart' as websocket_connect;
import '../p2p/chain/chainmessagehandler.dart';
import '../provider/app_data_provider.dart';
import '../tool/util.dart';

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
  SocketStatus status = SocketStatus.closed;
  Duration pingInterval = const Duration(seconds: 30);
  Map<String, dynamic> headers = {};
  Timer? heartBeat; // 心跳定时器
  int heartTimes = 3000; // 心跳间隔(毫秒)
  Function()? onConnected;

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
    logger.i('wss address:$address websocket connected');
    if (onConnected != null) {
      onConnected!();
    }
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
    logger.e("wss address:$address websocket onError, ${err}");
    status = SocketStatus.failed;
    await reconnect();
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
    if (channel != null && status == SocketStatus.connected) {
      channel!.sink.add(data);
    } else {
      logger.e('status is not connected');
      reconnect().then((value) {
        if (channel != null && status == SocketStatus.connected) {
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
    if (status != SocketStatus.closed) {
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
    int reconnectTimes = 5;
    Timer.periodic(Duration(milliseconds: heartTimes), (timer) async {
      if (reconnectTimes <= 0 || status == SocketStatus.connected) {
        timer.cancel();
        return;
      }
      reconnectTimes--;
      status = SocketStatus.reconnecting;
      logger.i('wss address:$address websocket reconnecting');
      await connect();
    });
  }
}

class WebsocketPool {
  static final WebsocketPool _instance = WebsocketPool();
  static bool initStatus = false;

  /// 初始化连接池，设置缺省websocketclient，返回连接池
  static Future<WebsocketPool> get instance async {
    if (!initStatus) {
      var appParams = AppDataProvider.instance;
      var nodeAddress = appParams.nodeAddress;
      if (nodeAddress.isNotEmpty) {
        NodeAddress? defaultNodeAddress = nodeAddress[NodeAddress.defaultName];
        if (defaultNodeAddress != null) {
          var defaultAddress = defaultNodeAddress.wsConnectAddress;
          if (defaultAddress != null && defaultAddress.startsWith('ws')) {
            var websocket = Websocket(defaultAddress);
            await websocket.connect();
            if (websocket.status == SocketStatus.connected) {
              _instance.websockets[defaultAddress] = websocket;
              _instance._default = websocket;
            }
          }
        }
      }
      initStatus = true;
    }
    return _instance;
  }

  var websockets = <String, Websocket>{};
  Websocket? _default;

  WebsocketPool();

  Future<Websocket?> get({String? address, bool isDefault = false}) async {
    if (address == null) {
      return _instance._default;
    }
    Websocket? websocket;
    if (websockets.containsKey(address)) {
      websocket = websockets[address];
    } else {
      if (address.startsWith('ws')) {
        websocket = Websocket(address);
        await websocket.connect();
        if (websocket.status == SocketStatus.connected) {
          _instance.websockets[address] = websocket;
        } else {
          websocket = null;
        }
      }
    }
    if (isDefault && websocket != null) {
      _instance._default = websocket;
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

final websocketPool = WebsocketPool.instance;
