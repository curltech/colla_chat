import 'dart:typed_data';

import 'package:colla_chat/crypto/signalprotocol.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../crypto/util.dart';
import '../../entity/chat/chat.dart';
import '../../entity/p2p/chain_message.dart';
import '../../p2p/chain/action/signal.dart';
import '../../pages/chat/me/webrtc/peer_connection_controller.dart';
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

  Iterable<String> keys() {
    return _elements.keys;
  }

  void clear() {
    _elements.clear();
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
  LruQueue<Map<String, AdvancedPeerConnection>> peerConnections = LruQueue();

  //所以注册的事件处理器
  Map<WebrtcEventType, Function(WebrtcEvent)> events = {};

  Map<String, dynamic> protocolHandlers = {};

  PeerConnectionPool() {
    signalAction.registerReceiver(onSignal);
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
  ///缺省情况下，所有的basePeerConnection的事件都已经注册成peerconnectionpool的相同方法处理
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
  /// @param peerId
  List<AdvancedPeerConnection>? get(String peerId) {
    if (peerConnections.containsKey(peerId)) {
      Map<String, AdvancedPeerConnection>? aps = peerConnections.use(peerId);
      if (aps != null) {
        return aps.values.toList();
      }
    }

    return null;
  }

  AdvancedPeerConnection? getOne(String peerId, {String? clientId}) {
    if (peerConnections.containsKey(peerId)) {
      Map<String, AdvancedPeerConnection>? aps = peerConnections.use(peerId);
      if (aps != null && aps.isNotEmpty) {
        if (clientId != null) {
          return aps[clientId];
        } else {
          return aps.values.first;
        }
      }
    }

    return null;
  }

  ///主动方创建，此时clientId有可能不知道
  Future<AdvancedPeerConnection?> create(String peerId,
      {String? clientId,
      String? name,
      Room? room,
      bool getUserMedia = false,
      List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers}) async {
    Map<String, AdvancedPeerConnection>? peerConnections =
        this.peerConnections.get(peerId);
    if (peerConnections != null && peerConnections.isNotEmpty) {
      if (clientId != null) {
        var peerConnection = peerConnections[clientId];
        if (peerConnection != null) {
          return peerConnection;
        }
      }
    }
    peerConnections ??= {};
    var peerConnection =
        AdvancedPeerConnection(peerId, true, clientId: clientId, room: room);
    peerConnectionPoolController.onCreated(
        WebrtcEvent(peerId, clientId: clientId, data: peerConnection));
    bool result =
        await peerConnection.init(streams: streams, iceServers: iceServers);
    if (!result) {
      logger.e('webrtcPeer.init fail');
      return null;
    }
    peerConnection.basePeerConnection.negotiate();
    //clientId没有值的时候以''代替
    clientId = clientId ?? '';
    peerConnections[clientId] = peerConnection;

    ///如果有溢出的连接，将溢出连接关闭
    Map<String, AdvancedPeerConnection>? outs =
        this.peerConnections.put(peerId, peerConnections);
    if (outs != null && outs.isNotEmpty) {
      for (AdvancedPeerConnection out in outs.values) {
        logger.e('over max webrtc peer number, knocked out');
        await out.close();
      }
    }
    return peerConnection;
  }

  ///从池中移除连接，不关心连接的状态
  Future<Map<String, AdvancedPeerConnection>?> remove(String peerId,
      {String? clientId}) async {
    Map<String, AdvancedPeerConnection>? peerConnections =
        this.peerConnections.get(peerId);
    if (peerConnections == null) {
      return null;
    }
    Map<String, AdvancedPeerConnection>? removePeerConnections = {};
    if (peerConnections.isNotEmpty) {
      List<String> clientIds = [];
      for (var entry in peerConnections.entries) {
        if (clientId == null || clientId == entry.value.clientId) {
          removePeerConnections[entry.key] = entry.value;
          clientIds.add(entry.key);
        }
      }
      for (String clientId in clientIds) {
        peerConnections.remove(clientId);
      }
      if (peerConnections.isEmpty) {
        this.peerConnections.remove(peerId);
      }

      return removePeerConnections;
    }
    return null;
  }

  ///主动关闭，从池中移除连接
  Future<bool> close(String peerId, {String? clientId}) async {
    Map<String, AdvancedPeerConnection>? removePeerConnections =
        await remove(peerId, clientId: clientId);
    if (removePeerConnections != null && removePeerConnections.isNotEmpty) {
      for (var entry in removePeerConnections.entries) {
        if (clientId == null || clientId == entry.value.clientId) {
          entry.value.close();
        }
      }
      return true;
    }
    return false;
  }

  /// 获取连接已经建立的连接，可能是多个
  /// @param peerId
  List<AdvancedPeerConnection>? getConnected(String peerId) {
    List<AdvancedPeerConnection> peerConnections_ = [];
    Map<String, AdvancedPeerConnection>? peerConnections =
        this.peerConnections.get(peerId);
    if (peerConnections != null && peerConnections.isNotEmpty) {
      for (AdvancedPeerConnection peerConnection in peerConnections.values) {
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
      for (var peer in peers.values) {
        peerConnections.add(peer);
      }
    }
    return peerConnections;
  }

  clear() async {
    for (var peerId in peerConnections.keys()) {
      Map<String, AdvancedPeerConnection>? peerConnections =
          this.peerConnections.get(peerId);
      if (peerConnections != null && peerConnections.isNotEmpty) {
        for (AdvancedPeerConnection peerConnection in peerConnections.values) {
          peerConnection.close();
        }
        peerConnections.clear();
      }
    }
    peerConnections.clear();
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
    String? name;
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
      if (name != extension.name) {
        name = extension.name;
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

    AdvancedPeerConnection? advancedPeerConnection;
    Map<String, AdvancedPeerConnection>? peerConnections =
        this.peerConnections.get(peerId);
    if (peerConnections != null && peerConnections.isNotEmpty) {
      advancedPeerConnection = peerConnections[clientId];
      if (advancedPeerConnection == null) {
        advancedPeerConnection = peerConnections[''];
        if (advancedPeerConnection != null) {
          logger.i(
              'for advancedPeerConnection peerId:$peerId, clientId:$clientId will replace');
          advancedPeerConnection.clientId = clientId;
          peerConnections.remove('');
          peerConnections[clientId] = advancedPeerConnection;
        }
      }
    }
    // peerId的连接存在，而且已经连接，报错
    if (advancedPeerConnection != null) {
      if (advancedPeerConnection.connected) {
        logger.e('peerId:$peerId clientId:$clientId is connected');
        return;
      }
    }

    //连接不存在，创建被叫连接，使用传来的iceServers，保证使用相同的turn服务器
    // logger.i('webrtcPeer:$peerId $clientId not exist, will create receiver');
    // if (iceServers != null) {
    //   for (var iceServer in iceServers) {
    //     if (iceServer['username'] == null) {
    //       iceServer['username'] = this.peerId!;
    //       iceServer['credential'] = peerPublicKey.toString();
    //     }
    //   }
    // }

    //作为主叫收到被叫的answer
    if ((signalType == SignalType.sdp.name && signal.sdp!.type == 'answer')) {
      //符合的主叫不存在，说明存在多个同peerid的被叫，其他的被叫的answer先来，将主叫占用了
      //需要再建新的主叫
      if (advancedPeerConnection == null) {
        logger.w('peerId:$peerId, clientId:$clientId has no master to match');
      }
    }
    if (signalType == SignalType.candidate.name ||
        (signalType == SignalType.sdp.name && signal.sdp!.type == 'offer')) {
      advancedPeerConnection ??= AdvancedPeerConnection(peerId, false,
          clientId: clientId, name: name, room: room);
      advancedPeerConnection.connectPeerId = connectPeerId;
      advancedPeerConnection.connectSessionId = connectSessionId;
      //新建的被叫连接放入池中

      peerConnections ??= {};
      peerConnections[clientId] = advancedPeerConnection;
      this.peerConnections.put(peerId, peerConnections);
      peerConnectionPoolController.onCreated(WebrtcEvent(peerId,
          clientId: clientId, data: advancedPeerConnection));

      if ((signalType == SignalType.sdp.name && signal.sdp!.type == 'offer')) {
        if (advancedPeerConnection.basePeerConnection.status ==
            PeerConnectionStatus.created) {
          var result =
              await advancedPeerConnection.init(iceServers: iceServers);
          if (!result) {
            logger.e('webrtcPeer.init fail');
            return null;
          }
        }
      }
    }

    if (advancedPeerConnection != null) {
      await advancedPeerConnection.onSignal(signal);
    }
  }

  /// 向peer发送信息，如果是多个，遍历发送
  /// @param peerId
  /// @param data
  Future<void> send(String peerId, List<int> data, {String? clientId}) async {
    List<AdvancedPeerConnection>? peerConnections = get(peerId);
    if (peerConnections != null && peerConnections.isNotEmpty) {
      List<Future<void>> ps = [];
      for (var peerConnection in peerConnections) {
        if (clientId == null || peerConnection.clientId == clientId) {
          Future<void> p = peerConnection.send(data);
          ps.add(p);
        }
      }
      await Future.wait(ps);
    }
    return;
  }

  ///收到发来的ChainMessage消息，进行后续的action处理
  ///webrtc的数据通道发来的消息可以是ChainMessage，也可以是简单的非ChainMessage
  onMessage(WebrtcEvent event) async {
    logger.i('peerId: ${event.peerId} clientId:${event.clientId} is onMessage');
    Map<String, dynamic> json = JsonUtil.toJson(event.data);
    ChatMessage chatMessage = ChatMessage.fromJson(json);
    chatMessageService.receiveChatMessage(chatMessage);
    var raw = CryptoUtil.decodeBase64(chatMessage.content);
    var content = CryptoUtil.utf8ToString(raw);
    logger.i('chatMessage content:$content');
    peerConnectionPoolController.onMessage(chatMessage);

    if (chatMessage.subMessageType == ChatSubMessageType.preKeyBundle.name) {
      PreKeyBundle? retrievedPreKeyBundle =
          signalSessionPool.signalKeyPair.preKeyBundleFromJson(content);
      if (retrievedPreKeyBundle != null) {
        SignalSession signalSession = signalSessionPool.create(
            peerId: peerId,
            clientId: clientId,
            deviceId: retrievedPreKeyBundle.getDeviceId(),
            retrievedPreKeyBundle: retrievedPreKeyBundle);
      } else {
        logger.i('chatMessage content transfer to PreKeyBundle failure');
      }
    }
  }

  onConnected(WebrtcEvent event) async {
    logger.i('peerId: ${event.peerId} clientId:${event.clientId} is connected');
    peerConnectionPoolController.onConnected(event);

    ///发送PreKeyBundle
    ChatMessage chatMessage = ChatMessage(myself.peerId!);
    chatMessage.subMessageType = ChatSubMessageType.preKeyBundle.name;
    PreKeyBundle preKeyBundle =
        signalSessionPool.signalKeyPair.getPreKeyBundle();
    chatMessage.content =
        signalSessionPool.signalKeyPair.preKeyBundleToJson(preKeyBundle);
    var data = CryptoUtil.stringToUtf8(JsonUtil.toJsonString(chatMessage));
    send(peerId, Uint8List.fromList(data), clientId: event.clientId);
  }

  onClosed(WebrtcEvent event) async {
    logger.i('peerId: ${event.peerId} clientId:${event.clientId} is closed');
    remove(event.peerId, clientId: event.clientId);
    peerConnectionPoolController.onClosed(event);
    signalSessionPool.close(peerId: peerId, clientId: clientId);
  }

  onError(WebrtcEvent event) async {
    logger.i('peerId: ${event.peerId} clientId:${event.clientId} is error');
    peerConnectionPoolController.onError(event);
  }

  onStream(WebrtcEvent event) async {
    logger.i('peerId: ${event.peerId} clientId:${event.clientId} is onStream');
    peerConnectionPoolController.onStream(event);
  }

  onTrack(WebrtcEvent event) async {
    logger.i('peerId: ${event.peerId} clientId:${event.clientId} is onTrack');
    peerConnectionPoolController.onTrack(event);
  }

  ///调用signalAction发送signal到信号服务器
  Future<dynamic> signal(WebrtcEvent evt) async {
    try {
      var peerId = evt.peerId;
      var clientId = evt.clientId;
      var result =
          await signalAction.signal(evt.data, peerId, targetClientId: clientId);
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
