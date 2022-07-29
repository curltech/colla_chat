import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../entity/p2p/message.dart';
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
    _head ??= key;
    _tail ??= key;
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
class PeerConnectionPool {
  ///自己的peerId,clientId和公钥
  late String peerId;
  late String clientId;
  late SimplePublicKey peerPublicKey;

  ///对方的队列，每一个peerId的元素是一个列表，具有相同的peerId和不同的clientId
  LruQueue<List<AdvancedPeerConnection>> peerConnections = LruQueue();

  //所以注册的事件处理器
  Map<WebrtcEventType, Function(WebrtcEvent)> events = {};

  Map<String, dynamic> protocolHandlers = {};

  PeerConnectionPool() {
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

    ///注册事件后，可以使用emit方法调用注册的事件方法
    on(WebrtcEventType.signal, signal);
    on(WebrtcEventType.message, onMessage);
  }

  ///webrtc onMessage接收到链协议消息的处理，收到的数据被转换成ChainMessage消息
  ///ChainMessageHandler类调用本方法注册
  registerProtocolHandler(String protocol, dynamic receiveHandler) {
    protocolHandlers[protocol] = {'receiveHandler': receiveHandler};
  }

  dynamic getProtocolHandler(String protocol) {
    return protocolHandlers[protocol];
  }

  ///注册事件，当事件发生时，调用外部注册的方法
  bool on(WebrtcEventType type, Function(WebrtcEvent)? func) {
    if (func != null) {
      events[type] = func;
      return true;
    } else {
      var fn = events.remove(type);
      if (fn != null) {
        return true;
      } else {
        return false;
      }
    }
  }

  ///调用外部注册事件方法
  Future<dynamic> emit(WebrtcEventType type, WebrtcEvent evt) async {
    if (events.containsKey(type)) {
      var func = events[type];
      if (func != null) {
        return await func(evt);
      } else {
        logger.e('event:$type is not func');
      }
    }
  }

  /// 获取peerId的webrtc连接，可能是多个
  /// 如果不存在，创建一个新的连接，发起连接尝试
  /// 否则，根据connected状态判断连接是否已经建立
  /// @param peerId
  List<AdvancedPeerConnection>? get(String peerId) {
    if (peerConnections.containsKey(peerId)) {
      return peerConnections.use(peerId);
    }

    return null;
  }

  AdvancedPeerConnection? getOne(String peerId, {String? clientId}) {
    List<AdvancedPeerConnection>? peerConnections = get(peerId);
    if (peerConnections != null && peerConnections.isNotEmpty) {
      if (clientId == null) {
        return peerConnections.first;
      }
      for (AdvancedPeerConnection peerConnection in peerConnections) {
        if (peerConnection.clientId == clientId) {
          return peerConnection;
        }
      }
    }

    return null;
  }

  ///主动方创建
  Future<AdvancedPeerConnection?> create(String peerId, String clientId,
      {bool getUserMedia = false,
      List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers,
      Room? router}) async {
    List<AdvancedPeerConnection>? peerConnections =
        this.peerConnections.get(peerId);
    peerConnections ??= [];
    var peerConnection = AdvancedPeerConnection();
    bool result = await peerConnection.init(peerId, clientId, true,
        getUserMedia: getUserMedia,
        streams: streams,
        iceServers: iceServers,
        room: router);
    if (!result) {
      logger.e('webrtcPeer.init fail');
      return null;
    }
    peerConnections.add(peerConnection);

    ///如果有溢出的连接，将溢出连接关闭
    List<AdvancedPeerConnection>? outs =
        this.peerConnections.put(peerId, peerConnections);
    if (outs != null && outs.isNotEmpty) {
      for (AdvancedPeerConnection out in outs) {
        logger.e('over max webrtc peer number, knocked out');
        await out.close();
      }
    }
    return peerConnection;
  }

  Future<bool> remove(String peerId, {String? clientId}) async {
    List<AdvancedPeerConnection>? peerConnections =
        this.peerConnections.get(peerId);
    if (peerConnections == null) {
      return false;
    }
    if (peerConnections.isNotEmpty) {
      for (AdvancedPeerConnection peerConnection in peerConnections) {
        if (clientId == null || clientId == peerConnection.clientId) {
          peerConnections.remove(peerConnection);
          await peerConnection.close();
        }
      }
      if (peerConnections.isEmpty) {
        this.peerConnections.remove(peerId);
      }

      return true;
    }
    return false;
  }

  Future<bool> removePeerConnection(
      String peerId, AdvancedPeerConnection peerConnection) async {
    List<AdvancedPeerConnection>? peerConnections =
        this.peerConnections.get(peerId);
    if (peerConnections != null && peerConnections.isNotEmpty) {
      bool connected_ = false;
      for (AdvancedPeerConnection peerConnection_ in peerConnections) {
        if (peerConnection_ == peerConnection) {
          logger.i('emit removeWebrtcPeer self');
          peerConnections.remove(peerConnection);
          await peerConnection.close();
        } else {
          logger.i('emit do not removeWebrtcPeer,because other');
          if (peerConnection_.connected) {
            connected_ = true;
            logger.i('other && connected');
          }
        }
      }
      if (peerConnections.isEmpty) {
        this.peerConnections.remove(peerId);
      }
      if (!connected_) {
        await emit(WebrtcEventType.close,
            WebrtcEvent(peerConnection.peerId, peerConnection.clientId));
      }

      return true;
    } else {
      return false;
    }
  }

  /// 获取连接已经建立的连接，可能是多个
  /// @param peerId
  List<AdvancedPeerConnection>? getConnected(String peerId) {
    List<AdvancedPeerConnection> peerConnections_ = [];
    List<AdvancedPeerConnection>? peerConnections =
        this.peerConnections.get(peerId);
    if (peerConnections != null && peerConnections.isNotEmpty) {
      for (AdvancedPeerConnection peerConnection in peerConnections) {
        if (peerConnection.connected) {
          peerConnections_.add(peerConnection);
        }
      }
    }
    if (peerConnections_.isNotEmpty) {
      return peerConnections_;
    }

    return null;
  }

  List<AdvancedPeerConnection> getAll() {
    List<AdvancedPeerConnection> peerConnections = [];
    for (var peers in this.peerConnections.all) {
      for (var peer in peers) {
        peerConnections.add(peer);
      }
    }
    return peerConnections;
  }

  clear() async {
    var peerConnections = getAll();
    for (var peerConnection in peerConnections) {
      var peerId = peerConnection.peerId;
      if (peerId != null) {
        await remove(peerId);
      }
    }
  }

  /// 接收到信号服务器发来的signal的处理,没有完成，要仔细考虑多终端的情况
  /// 如果发来的是answer,寻找主叫的peerId,必须找到，否则报错，找到后检查clientId
  /// 如果发来的是offer,检查peerId，没找到创建一个新的被叫，如果找到，检查clientId
  /// @param peerId
  /// @param connectSessionId
  /// @param data
  onSignal(ChainMessage chainMessage) async {
    String? peerId = chainMessage.srcPeerId;
    String? connectPeerId = chainMessage.srcConnectPeerId;
    String? connectSessionId = chainMessage.srcConnectSessionId;
    WebrtcSignal signal = chainMessage.payload;
    var signalType = signal.signalType;
    logger.i('receive signal type: $signalType from webrtcPeer: $peerId');
    String? clientId = chainMessage.srcClientId;
    List<Map<String, String>>? iceServers;
    Room? room;
    var extension = signal.extension;
    if (extension != null) {
      if (peerId != extension.peerId) {
        logger.e(
            'peerId:$peerId extension peerId:${extension.peerId} is not same');
        peerId = extension.peerId;
      }
      if (clientId != extension.clientId) {
        logger.e(
            'peerId:$peerId extension peerId:${extension.peerId} is not same');
        clientId = extension.clientId;
      }
      iceServers = extension.iceServers;
      room = extension.room;
    }
    if (peerId == null) {
      logger.e('peerId is null');
      return;
    }
    if (clientId == null) {
      logger.e('clientId is null');
      return;
    }
    AdvancedPeerConnection? advancedPeerConnection =
        getOne(peerId!, clientId: clientId);
    // peerId的连接存在，而且已经连接，报错
    if (advancedPeerConnection != null) {
      if (advancedPeerConnection.connected) {
        logger.e('peerId:$peerId clientId:$clientId is connected');
        return;
      }
    } else {
      //连接不存在，创建被叫连接，使用传来的iceServers，保证使用相同的turn服务器
      logger.i('webrtcPeer:$peerId $clientId not exist, will create receiver');
      if (iceServers != null) {
        for (var iceServer in iceServers) {
          if (iceServer['username'] == null) {
            iceServer['username'] = this.peerId!;
            iceServer['credential'] = peerPublicKey.toString();
          }
        }
      }
      advancedPeerConnection = AdvancedPeerConnection();
      var result = await advancedPeerConnection.init(peerId, clientId, false,
          getUserMedia: false, iceServers: iceServers, room: room);
      if (!result) {
        logger.e('webrtcPeer.init fail');
        return null;
      }
      advancedPeerConnection.connectPeerId = connectPeerId;
      advancedPeerConnection.connectSessionId = connectSessionId;
      //新建的被叫连接放入池中
      List<AdvancedPeerConnection>? peerConnections =
          this.peerConnections.get(peerId);
      peerConnections ??= [];
      peerConnections.add(advancedPeerConnection);
      this.peerConnections.put(peerId, peerConnections);
      emit(WebrtcEventType.create,
          WebrtcEvent(peerId, clientId, data: advancedPeerConnection));
    }

    await advancedPeerConnection.signal(signal);
  }

  /// 向peer发送信息，如果是多个，遍历发送
  /// @param peerId
  /// @param data
  send(String peerId, Uint8List data) async {
    List<AdvancedPeerConnection>? peerConnections = get(peerId);
    if (peerConnections != null && peerConnections.isNotEmpty) {
      List<Future> ps = [];
      for (var peerConnection in peerConnections) {
        Future p = peerConnection.send(data);
        ps.add(p);
      }
      await Future.wait(ps);
    }
  }

  ///收到发来的ChainMessage消息，进行后续的action处理
  ///webrtc的数据通道发来的消息可以是ChainMessage，也可以是简单的非ChainMessage
  onMessage(dynamic event) async {
    var appDataProvider = AppDataProvider.instance;
    var chainProtocolId = appDataProvider.chainProtocolId;
    var receiveHandler = getProtocolHandler(chainProtocolId);
    if (receiveHandler != null) {
      var remotePeerId = event.source.receiverPeerId;
      //调用注册的接收处理器处理接收的原始数据
      Uint8List? data = await receiveHandler(event.message, remotePeerId, null);
      //如果有返回的响应数据，则发送回去，不可以调用同步的发送方法send
      if (data != null) {
        send(remotePeerId, data);
      }
    }
  }

  ///调用signalAction发送signal到信号服务器
  Future<dynamic> signal(WebrtcEvent evt) async {
    try {
      var peerId = evt.peerId;
      var clientId = evt.clientId;
      var result = await signalAction.signal(evt.data, peerId, clientId);
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

final peerConnectionPool = PeerConnectionPool();
