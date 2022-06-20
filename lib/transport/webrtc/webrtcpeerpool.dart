import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/transport/webrtc/webrtc_core_peer.dart';
import 'package:colla_chat/transport/webrtc/webrtc_peer.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../p2p/chain/action/signal.dart';
import '../../provider/app_data_provider.dart';

///一个队列，按照被使用的新旧排序，当元素超过最大数量的时候，溢出最旧的元素
class LruQueue<T> {
  int _maxLength = 200;
  final Map<String, T> _elements = {};

  //指向比自己新的元素的键值，只有最新的键值例外，指向第二新的键值
  final Map<String, String> _nexts = {};

  //最新的元素的键值
  String? _head;

  //最老的元素的键值
  String? _tail;

  LruQueue({int maxLength = 200}) {
    _maxLength = _maxLength;
  }

  //把key的元素变为最新，当前的最新的变为第二新
  T? use(String key) {
    var element = _elements[key];
    if (element == null) {
      return null;
    }
    if (key == _tail) {
      _tail = _nexts[_tail];
    }
    var head = _head;
    if (head != null) {
      _nexts[key] = head;
    }
    _head = key;

    return element;
  }

  // 放置新的元素，并成为最新的，如果有溢出元素，则返回溢出的元素
  T? put(String key, T element) {
    T? tail;
    _elements[key] = element;
    if (_head == null) {
      _head = key;
    }
    if (_tail == null) {
      _tail = key;
    }
    if (_elements.length > _maxLength) {
      tail = _elements[_tail];
      _elements.remove(_tail);
      _tail = _nexts[_tail];
    }
    use(key);

    return tail;
  }

  //移除元素，并返回
  T? remove(String key) {
    T? out = _elements.remove(key);
    if (out != null) {
      if (key == _head) {
        var second = _nexts[_head];
        var third = _nexts[second];
        _head = second;
        if (second != null && third != null) {
          _nexts[second] = third;
        }
      }
      if (key == _tail) {
        _tail = _nexts[_tail];
      }
    }

    return out;
  }

  T? get(String key) {
    return _elements[key];
  }

  bool containsKey(String key) {
    return _elements.containsKey(key);
  }

  int get length {
    return _elements.length;
  }

  List<T> get all {
    return _elements.values.toList();
  }
}

/// webrtc的连接池，键值是对方的peerId
class WebrtcPeerPool {
  static late WebrtcPeerPool _instance;
  static bool initStatus = false;

  ///自己的peerId,clientId和公钥
  late String peerId;
  late SimplePublicKey peerPublicKey;
  late String clientId;

  ///对方的队列，每一个peerId的元素是一个列表，具有相同的peerId和不同的clientId
  LruQueue<List<WebrtcPeer>> webrtcPeers = LruQueue();

  //所以注册的事件处理器
  Map<String, Function> events = {};

  //signal事件的处理器
  late SignalAction _signalAction;
  Map<String, dynamic> protocolHandlers = {};

  static WebrtcPeerPool get instance {
    if (!initStatus) {
      _instance = WebrtcPeerPool();
      _instance.registerSignalAction(signalAction);
      initStatus = true;
    }

    return _instance;
  }

  WebrtcPeerPool() {
    var peerId = myself.peerId;
    if (peerId == null) {
      throw 'myself peerId is null';
    }
    this.peerId = peerId;
    var clientId = myself.clientId;
    if (clientId == null) {
      throw 'myself clientId is null';
    }
    this.clientId = clientId;
    var peerPublicKey = myself.peerPublicKey;
    if (peerPublicKey == null) {
      throw 'myself peerPublicKey is null';
    }
    this.peerPublicKey = peerPublicKey;
    _signalAction = signalAction;
    registerEvent(WebrtcEventType.signal.name, sendSignal);
    registerEvent(WebrtcEventType.data.name, receiveData);
  }

  registerSignalAction(SignalAction signalAction) {
    _signalAction.registerReceiver(
        'webrtcPeerPool', WebrtcPeerPool.instance.receive);
  }

  registerProtocolHandler(String protocol, dynamic receiveHandler) {
    protocolHandlers[protocol] = {'receiveHandler': receiveHandler};
  }

  dynamic getProtocolHandler(String protocol) {
    return protocolHandlers[protocol];
  }

  /// 获取peerId的webrtc连接，可能是多个
  /// 如果不存在，创建一个新的连接，发起连接尝试
  /// 否则，根据connected状态判断连接是否已经建立
  /// @param peerId
  List<WebrtcPeer>? get(String peerId) {
    if (webrtcPeers.containsKey(peerId)) {
      return webrtcPeers.use(peerId);
    }

    return null;
  }

  WebrtcPeer? getOne(String peerId, String clientId) {
    List<WebrtcPeer>? webrtcPeers = get(peerId);
    if (webrtcPeers != null && webrtcPeers.isNotEmpty) {
      for (WebrtcPeer webrtcPeer in webrtcPeers) {
        if (webrtcPeer.clientId == clientId) {
          return webrtcPeer;
        }
      }
    }

    return null;
  }

  ///主动方创建
  Future<WebrtcPeer?> create(String peerId, String clientId,
      {List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers,
      Router? router}) async {
    List<WebrtcPeer>? webrtcPeers = this.webrtcPeers.get(peerId);
    if (webrtcPeers == null) {
      webrtcPeers = [];
    }
    var webrtcPeer = WebrtcPeer();
    bool result = await webrtcPeer.init(peerId, clientId, true,
        streams: streams, iceServers: iceServers, router: router);
    if (!result) {
      logger.e('webrtcPeer.init fail');
      return null;
    }
    webrtcPeers.add(webrtcPeer);

    ///如果有溢出的连接，将溢出连接关闭
    List<WebrtcPeer>? outs = this.webrtcPeers.put(peerId, webrtcPeers);
    if (outs != null && outs.isNotEmpty) {
      for (WebrtcPeer out in outs) {
        await out.destroy('over max webrtc peer number, knocked out');
      }
    }
    return webrtcPeer;
  }

  Future<bool> remove(String peerId, {String? clientId}) async {
    List<WebrtcPeer>? webrtcPeers = this.webrtcPeers.get(peerId);
    if (webrtcPeers == null) {
      return false;
    }
    if (webrtcPeers.isNotEmpty) {
      for (WebrtcPeer webrtcPeer in webrtcPeers) {
        if (clientId == null ||
            webrtcPeer.clientId == null ||
            clientId == webrtcPeer.clientId) {
          webrtcPeers.remove(webrtcPeer);
          await webrtcPeer.destroy('remove webrtcPeer');
        }
      }
      if (webrtcPeers.isEmpty) {
        this.webrtcPeers.remove(peerId);
      }

      return true;
    }
    return false;
  }

  Future<bool> removeWebrtcPeer(String peerId, WebrtcPeer webrtcPeer) async {
    List<WebrtcPeer>? webrtcPeers = this.webrtcPeers.get(peerId);
    if (webrtcPeers != null && webrtcPeers.isNotEmpty) {
      bool _connected = false;
      for (WebrtcPeer _webrtcPeer in webrtcPeers) {
        if (_webrtcPeer == webrtcPeer) {
          logger.i('emit removeWebrtcPeer self');
          webrtcPeers.remove(webrtcPeer);
          await webrtcPeer.destroy('rmoved');
        } else {
          logger.i('emit do not removeWebrtcPeer,because other');
          if (_webrtcPeer.connected) {
            _connected = true;
            logger.i('other && connected');
          }
        }
      }
      if (webrtcPeers.isEmpty) {
        WebrtcPeerPool.instance.webrtcPeers.remove(peerId);
      }
      if (!_connected) {
        await emit(WebrtcEventType.close.name,
            WebrtcEvent(webrtcPeer.peerId, webrtcPeer.clientId));
      }

      return true;
    } else {
      return false;
    }
  }

  /// 获取连接已经建立的连接，可能是多个
  /// @param peerId
  List<WebrtcPeer>? getConnected(String peerId) {
    List<WebrtcPeer> peers = [];
    List<WebrtcPeer>? webrtcPeers = this.webrtcPeers.get(peerId);
    if (webrtcPeers != null && webrtcPeers.isNotEmpty) {
      for (WebrtcPeer webrtcPeer in webrtcPeers) {
        if (webrtcPeer.connected) {
          peers.add(webrtcPeer);
        }
      }
    }
    if (peers.isNotEmpty) {
      return peers;
    }

    return null;
  }

  List<WebrtcPeer> getAll() {
    List<WebrtcPeer> webrtcPeers = [];
    for (var peers in this.webrtcPeers.all) {
      for (var peer in peers) {
        webrtcPeers.add(peer);
      }
    }
    return webrtcPeers;
  }

  clear() async {
    var webrtcPeers = getAll();
    for (var peer in webrtcPeers) {
      var peerId = peer.peerId;
      if (peerId != null) {
        await remove(peerId);
      }
    }
  }

  /// 接收到signal的处理,没有完成，要仔细考虑多终端的情况
  /// 如果发来的是answer,寻找主叫的peerId,必须找到，否则报错，找到后检查clientId
  /// 如果发来的是offer,检查peerId，没找到创建一个新的被叫，如果找到，检查clientId
  /// @param peerId
  /// @param connectSessionId
  /// @param data
  receive(String peerId, String connectPeerId, String connectSessionId,
      WebrtcSignal signal) async {
    var signalType = signal.signalType;
    logger.i('receive signal type: $signalType from webrtcPeer: $peerId');
    String? clientId;
    List<Map<String, String>>? iceServers;
    Router? router;
    var extension = signal.extension;
    if (extension != null) {
      if (peerId != extension.peerId) {
        logger.e(
            'peerId:$peerId extension peerId:${extension.peerId} is not same');
        return;
      }
      clientId = extension.clientId;
      iceServers = extension.iceServers;
      router = extension.router;
    }
    if (clientId == null) {
      logger.e('clientId is null');
      return;
    }
    WebrtcPeer? webrtcPeer = getOne(peerId, clientId);
    // peerId的连接存在，而且已经连接，报错
    if (webrtcPeer != null) {
      if (webrtcPeer.connected) {
        logger.e('peerId:$peerId clientId:$clientId is connected');
        return;
      }
    }
    //sdp信号
    var sdp = signal.sdp;
    if (signalType == 'sdp' && sdp != null) {
      var type = sdp.type;
      //如果是offer信号，创建新的被叫连接
      if (type == 'offer') {
        logger
            .i('webrtcPeer:$peerId $clientId not exist, will create receiver');
        if (iceServers != null) {
          for (var iceServer in iceServers) {
            if (iceServer['username'] == null) {
              iceServer['username'] = this.peerId!;
              iceServer['credential'] = peerPublicKey.toString();
            }
          }
        }
        // peerId的连接存在且未完成连接，重复收到offer，报错
        if (webrtcPeer != null) {
          logger.e(
              'peerId:$peerId clientId:$clientId is exist, but is not connected completely');
          return;
        }
        webrtcPeer = WebrtcPeer();
        var result = await webrtcPeer.init(peerId, clientId, false,
            iceServers: iceServers, router: router);
        if (!result) {
          logger.e('webrtcPeer.init fail');
          return null;
        }
        webrtcPeer.connectPeerId = connectPeerId;
        webrtcPeer.connectSessionId = connectSessionId;
        List<WebrtcPeer>? webrtcPeers = this.webrtcPeers.get(peerId);
        if (webrtcPeers == null) {
          webrtcPeers = [];
        }
        webrtcPeers.add(webrtcPeer);
        this.webrtcPeers.put(peerId, webrtcPeers);
        await webrtcPeer.signal(signal);
      } else if (type == 'answer') {
        // peerId的连接不存在，报错
        if (webrtcPeer == null) {
          logger.e('peerId:$peerId clientId:$clientId is not exist');
          return;
        }
        if (webrtcPeer.connectPeerId == null) {
          webrtcPeer.connectPeerId = connectPeerId;
          webrtcPeer.connectSessionId = connectSessionId;
        }
        await webrtcPeer.signal(signal);
      } else {
        logger.e('sdp is not offer or answer,err');
        return;
      }
    }
  }

  /// 向peer发送信息，如果是多个，遍历发送
  /// @param peerId
  /// @param data
  send(String peerId, Uint8List data) async {
    List<WebrtcPeer>? webrtcPeers = get(peerId);
    if (webrtcPeers != null && webrtcPeers.isNotEmpty) {
      List<Future> ps = [];
      for (var webrtcPeer in webrtcPeers) {
        Future p = webrtcPeer.send(data);
        ps.add(p);
      }
      await Future.wait(ps);
    }
  }

  ///收到发来的ChainMessage消息，进行后续的action处理
  ///webrtc的数据通道发来的消息可以是ChainMessage，也可以是简单的非ChainMessage
  receiveData(dynamic event) async {
    var appDataProvider = AppDataProvider.instance;
    var chainProtocolId = appDataProvider.chainProtocolId;
    var receiveHandler = getProtocolHandler(chainProtocolId);
    if (receiveHandler != null) {
      var remotePeerId = event.source.targetPeerId;
      //调用注册的接收处理器处理接收的原始数据
      Uint8List? data = await receiveHandler(event.data, remotePeerId, null);
      //如果有返回的响应数据，则发送回去，不可以调用同步的发送方法send
      if (data != null) {
        WebrtcPeerPool.instance.send(remotePeerId, data);
      }
    }
  }

  bool registerEvent(String name, Function? func) {
    if (func != null) {
      events[name] = func;
      return true;
    } else {
      var fn = events.remove(name);
      if (fn != null) {
        return true;
      } else {
        return false;
      }
    }
  }

  Future<dynamic> emit(String name, WebrtcEvent evt) async {
    if (events.containsKey(name)) {
      var func = events[name];
      if (func != null) {
        return await func(evt);
      } else {
        logger.e('event:$name is not func');
      }
    }
  }

  Future<dynamic> sendSignal(WebrtcEvent evt) async {
    try {
      var peerId = evt.peerId;
      var result = await _signalAction.signal(evt.data, peerId);
      if (result == 'ERROR') {
        logger.e('signal err:$result');
      }
      return result;
    } catch (err) {
      logger.e('signal err:$err');
    }
    return null;
  }
}
