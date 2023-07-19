import 'dart:async';

import 'package:colla_chat/crypto/signalprotocol.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/action/signal.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:synchronized/extension.dart';

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

  Map<String, List<Future<dynamic> Function(WebrtcEvent event)>> fnsm = {};

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
    Timer.periodic(const Duration(seconds: 60), (Timer timer) {
      clear();
    });
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

  String _getKey(String peerId, WebrtcEventType eventType) {
    return '$peerId:${eventType.name}';
  }

  registerWebrtcEvent(String peerId, WebrtcEventType eventType,
      Future<dynamic> Function(WebrtcEvent) fn) {
    String key = _getKey(peerId, eventType);
    List<Future<void> Function(WebrtcEvent)>? fns = fnsm[key];
    if (fns == null) {
      fns = [];
      fnsm[key] = fns;
    }
    fns.add(fn);
  }

  unregisterWebrtcEvent(String peerId, WebrtcEventType eventType,
      Future<dynamic> Function(WebrtcEvent) fn) {
    String key = _getKey(peerId, eventType);
    List<Future<void> Function(WebrtcEvent)>? fns = fnsm[key];
    if (fns == null) {
      return;
    }
    fns.remove(fn);
    if (fns.isEmpty) {
      fnsm.remove(key);
    }
  }

  Future<List> onWebrtcEvent(WebrtcEvent event) async {
    String peerId = event.peerId;
    WebrtcEventType eventType = event.eventType;
    logger.w('Webrtc peer connection $peerId webrtcEvent $eventType coming');
    String key = _getKey(peerId, eventType);
    List<Future<dynamic> Function(WebrtcEvent)>? fns = fnsm[key];
    var results = [];
    if (fns != null) {
      for (var fn in fns) {
        results.add(await fn(event));
      }
    }

    return results;
  }

  /// 获取peerId的webrtc连接，可能是多个
  /// @param peerId
  List<AdvancedPeerConnection> get(String peerId) {
    if (peerConnections.containsKey(peerId)) {
      Map<String, AdvancedPeerConnection>? aps = peerConnections.use(peerId);
      if (aps != null) {
        return aps.values.toList();
      }
    }

    return [];
  }

  AdvancedPeerConnection? getOne(String peerId, {required String clientId}) {
    if (peerConnections.containsKey(peerId)) {
      Map<String, AdvancedPeerConnection>? aps = peerConnections.use(peerId);
      if (aps != null && aps.isNotEmpty) {
        return aps[clientId];
      }
    }

    return null;
  }

  Future<void> put(
    String peerId,
    AdvancedPeerConnection advancedPeerConnection, {
    String clientId = unknownClientId,
  }) async {
    var peerConnections = this.peerConnections.get(peerId);
    peerConnections = peerConnections ?? {};
    AdvancedPeerConnection? old = peerConnections[clientId];
    if (old != null) {
      logger.w('old peerId:$peerId clientId:$clientId is exist!');
    }
    peerConnections[clientId] = advancedPeerConnection;

    ///如果有溢出的连接，将溢出连接关闭
    Map<String, AdvancedPeerConnection>? outs =
        this.peerConnections.put(peerId, peerConnections);
    if (outs != null && outs.isNotEmpty) {
      for (AdvancedPeerConnection out in outs.values) {
        logger.e('over max webrtc peer number, knocked out');
        await out.close();
      }
    }
  }

  ///主动方创建，此时clientId有可能不知道，如果已经存在，先关闭删除
  Future<AdvancedPeerConnection?> create(String peerId,
      {String clientId = unknownClientId,
      Conference? conference,
      List<Map<String, String>>? iceServers,
      List<PeerVideoRender> localRenders = const []}) async {
    //如果已经存在，先关闭删除
    AdvancedPeerConnection? peerConnection = getOne(peerId, clientId: clientId);
    if (peerConnection != null) {
      await close(peerId, clientId: clientId);
      logger.i(
          'peerId:$peerId clientId:$clientId is closed and will be re-created!');
    }
    //创建新的主叫方
    peerConnection = AdvancedPeerConnection(peerId, true, clientId: clientId);
    String name = unknownName;
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
    if (linkman != null) {
      name = linkman.name;
    }
    bool result = await peerConnection.init(
        iceServers: iceServers, localRenders: localRenders);
    if (!result) {
      logger.e('webrtcPeer.init fail');
      return null;
    }
    onWebrtcEvent(WebrtcEvent(peerId,
        clientId: clientId,
        name: name,
        eventType: WebrtcEventType.created,
        data: peerConnection));
    await peerConnection.negotiate();
    await put(peerId, peerConnection, clientId: clientId);

    return peerConnection;
  }

  ///从池中移除连接，不关心连接的状态
  Map<String, AdvancedPeerConnection>? remove(String peerId,
      {String? clientId}) {
    Map<String, AdvancedPeerConnection>? peerConnections =
        this.peerConnections.get(peerId);
    if (peerConnections == null) {
      return null;
    }
    Map<String, AdvancedPeerConnection>? removePeerConnections = {};
    if (peerConnections.isNotEmpty) {
      if (clientId == null) {
        removePeerConnections.addAll(peerConnections);
        peerConnections.clear();
      } else {
        AdvancedPeerConnection? advancedPeerConnection =
            peerConnections.remove(clientId);
        if (advancedPeerConnection != null) {
          removePeerConnections[advancedPeerConnection.clientId] =
              advancedPeerConnection;
        }
        logger.i('remove peerConnection peerId:$peerId,clientId:$clientId');
      }
      if (peerConnections.isEmpty) {
        this.peerConnections.remove(peerId);
      }

      return removePeerConnections;
    }
    return null;
  }

  ///主动关闭，从池中移除连接
  Future<bool> close(String peerId, {required String clientId}) async {
    Map<String, AdvancedPeerConnection>? removePeerConnections =
        remove(peerId, clientId: clientId);
    if (removePeerConnections != null && removePeerConnections.isNotEmpty) {
      for (var entry in removePeerConnections.entries) {
        if (clientId == entry.value.clientId) {
          await entry.value.close();
          logger.i('peerId:$peerId clientId:$clientId is closed!');
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

  ///清除过一段时间仍没有连接上的连接
  clear() async {
    List<String> removedPeerIds = [];
    for (var peerId in peerConnections.keys()) {
      Map<String, AdvancedPeerConnection>? peerConnections =
          this.peerConnections.get(peerId);
      if (peerConnections != null && peerConnections.isNotEmpty) {
        List<String> removedClientIds = [];
        for (AdvancedPeerConnection peerConnection in peerConnections.values) {
          if (peerConnection.basePeerConnection.status !=
              PeerConnectionStatus.connected) {
            var start = peerConnection.basePeerConnection.start;
            var now = DateTime.now().millisecondsSinceEpoch;
            var gap = now - start!;
            var limit = const Duration(seconds: 20);
            if (gap > limit.inMilliseconds) {
              removedClientIds.add(peerConnection.clientId!);
              logger.e(
                  'peerConnection peerId:${peerConnection.peerId},clientId:${peerConnection.clientId} is overtime unconnected');
            }
          }
        }
        for (var removedClientId in removedClientIds) {
          peerConnections.remove(removedClientId);
        }
        if (peerConnections.isEmpty) {
          removedPeerIds.add(peerId);
        }
      }
    }
    for (var removedPeerId in removedPeerIds) {
      peerConnections.remove(removedPeerId);
    }
  }

  //var lock = Lock(reentrant: true);

  ///如果不存在，创建被叫，如果存在直接返回
  Future<AdvancedPeerConnection?> createIfNotExist(String peerId,
      {required String clientId,
      required String name,
      Conference? conference,
      List<Map<String, String>>? iceServers}) async {
    return await synchronized(() async {
      return await _createIfNotExist(peerId,
          clientId: clientId,
          name: name,
          conference: conference,
          iceServers: iceServers);
    });
  }

  Future<AdvancedPeerConnection?> _createIfNotExist(String peerId,
      {required String clientId,
      required String name,
      Conference? conference,
      List<Map<String, String>>? iceServers}) async {
    AdvancedPeerConnection? advancedPeerConnection =
        getOne(peerId, clientId: clientId);
    if (advancedPeerConnection == null) {
      logger.i('advancedPeerConnection is null,create new one');
      advancedPeerConnection =
          AdvancedPeerConnection(peerId, false, clientId: clientId, name: name);
      await put(peerId, advancedPeerConnection, clientId: clientId);
      var result = await advancedPeerConnection.init(iceServers: iceServers);
      if (!result) {
        logger.e('webrtcPeer.init fail');
        return null;
      }
      onWebrtcEvent(WebrtcEvent(peerId,
          clientId: clientId,
          name: name,
          eventType: WebrtcEventType.created,
          data: advancedPeerConnection));
      logger.i(
          'advancedPeerConnection ${advancedPeerConnection.basePeerConnection.id} init completed');
    }

    return advancedPeerConnection;
  }

  ///从信号服务器传来的webrtc的协商消息
  Future<void> onSignal(ChainMessage chainMessage) async {
    if (chainMessage.srcPeerId == null) {
      logger.e('chainMessage.srcPeerId is null');
      return;
    }
    String peerId = chainMessage.srcPeerId!;
    String clientId = chainMessage.srcClientId!;
    WebrtcSignal signal = chainMessage.payload;
    await onWebrtcSignal(peerId, signal, clientId: clientId);
  }

  /// 接收到信号服务器发来的signal的处理,没有完成，要仔细考虑多终端的情况
  /// 如果发来的是answer,寻找主叫的peerId,必须找到，否则报错，找到后检查clientId
  /// 如果发来的是offer,检查peerId，没找到创建一个新的被叫，如果找到，检查clientId
  /// @param peerId
  /// @param connectSessionId
  /// @param data
  onWebrtcSignal(String peerId, WebrtcSignal signal,
      {required String clientId}) async {
    var signalType = signal.signalType;
    logger.w('receive signal type: $signalType from webrtcPeer: $peerId');
    String name = unknownName;
    List<Map<String, String>>? iceServers;
    Conference? conference;
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
      name = extension.name;
      iceServers = extension.iceServers;
      conference = extension.conference;
    }

    ///收到信号，连接已经存在，但是clientId为unknownClientId，表明自己是主叫，建立的时候对方的clientId未知
    ///设置clientId和name
    AdvancedPeerConnection? advancedPeerConnection =
        getOne(peerId, clientId: unknownClientId);
    if (advancedPeerConnection != null) {
      advancedPeerConnection.clientId = clientId;
      advancedPeerConnection.name = name;
      remove(peerId, clientId: unknownClientId);
      await put(peerId, advancedPeerConnection, clientId: clientId);
    }
    advancedPeerConnection = getOne(peerId, clientId: clientId);
    // peerId的连接存在，而且已经连接，报错
    if (advancedPeerConnection != null) {
      if (advancedPeerConnection.connected) {
        logger.w(
            'peerId:$peerId clientId:$clientId is connected, maybe renegotiate');
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
    } else if (signalType == SignalType.candidate.name ||
        (signalType == SignalType.sdp.name && signal.sdp!.type == 'offer')) {
      if (advancedPeerConnection == null) {
        WebrtcEvent webrtcEvent = WebrtcEvent(peerId,
            clientId: clientId,
            name: name,
            eventType: WebrtcEventType.signal,
            data: signal);
        bool? allowed =
            await globalWebrtcEventController.receiveWebrtcEvent(webrtcEvent);
        if (allowed != null && allowed) {
          advancedPeerConnection = await createIfNotExist(peerId,
              clientId: clientId,
              name: name,
              conference: conference,
              iceServers: iceServers);
          if (advancedPeerConnection == null) {
            logger.e('createIfNotExist fail');
            return null;
          }
        } else {
          String error = 'peerId:$peerId can not receive a webrtc connection';
          logger.e(error);
          WebrtcSignal webrtcSignal =
              WebrtcSignal(SignalType.error.name, error: error);
          WebrtcEvent webrtcEvent = WebrtcEvent(peerId,
              clientId: clientId,
              name: name,
              eventType: WebrtcEventType.signal,
              data: webrtcSignal);
          if (advancedPeerConnection != null) {
            await advancedPeerConnection.signal(webrtcEvent);
          }

          return null;
        }
      }
    }

    ///转发信号到base层处理，包括renegotiate
    if (advancedPeerConnection != null) {
      await advancedPeerConnection.onSignal(signal);
    }
  }

  /// 向peer发送信息，如果是多个，遍历发送
  Future<bool> send(String peerId, List<int> data) async {
    List<AdvancedPeerConnection> peerConnections = get(peerId);
    if (peerConnections.isNotEmpty) {
      List<Future<bool>> ps = [];
      for (var peerConnection in peerConnections) {
        if (peerConnection.status == PeerConnectionStatus.connected) {
          Future<bool> p = peerConnection.send(data);
          //logger.w('send signal');
          ps.add(p);
        }
      }
      List<bool> results = await Future.wait(ps);
      if (results.isNotEmpty) {
        for (var result in results) {
          if (result) {
            return true;
          }
        }
      }
    } else {
      logger.e(
          'PeerConnection:$peerId,clientId;$clientId is not exist, cannot send');
    }
    return false;
  }

  ///收到发来的ChatMessage的payload（map对象），进行后续的action处理
  onMessage(WebrtcEvent event) async {
    onWebrtcEvent(event);
  }

  onStatusChanged(WebrtcEvent event) async {
    onWebrtcEvent(event);
  }

  ///webrtc连接完成后首先交换最新的联系人信息，然后请求新的订阅渠道消息
  ///然后交换棘轮加密的密钥
  onConnected(WebrtcEvent event) async {
    globalChatMessageController.sendModifyLinkman(event.peerId,
        clientId: event.clientId);
    globalChatMessageController.sendGetChannel(event.peerId,
        clientId: event.clientId);
    globalChatMessageController.sendPreKeyBundle(event.peerId,
        clientId: event.clientId);
    onWebrtcEvent(event);

    ///连接完成后，清除暂存的连接许可，保证下次需要重新申请许可
    globalWebrtcEventController.results.remove(event.peerId);
  }

  ///从池中移除连接
  onClosed(WebrtcEvent event) async {
    remove(event.peerId, clientId: event.clientId);
    onWebrtcEvent(event);
    signalSessionPool.close(peerId: event.peerId, clientId: event.clientId);
  }

  onError(WebrtcEvent event) async {
    onWebrtcEvent(event);
  }

  onAddStream(WebrtcEvent event) async {
    onWebrtcEvent(event);
  }

  onRemoveStream(WebrtcEvent event) async {
    onWebrtcEvent(event);
  }

  onTrack(WebrtcEvent event) async {
    onWebrtcEvent(event);
  }

  onAddTrack(WebrtcEvent event) async {
    onWebrtcEvent(event);
  }

  onRemoveTrack(WebrtcEvent event) async {
    onWebrtcEvent(event);
  }

  removeTrack(String peerId, MediaStream stream, MediaStreamTrack track,
      {required String clientId}) async {
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (advancedPeerConnection != null) {
      await advancedPeerConnection.removeTrack(stream, track);
    }
  }

  replaceTrack(String peerId, MediaStream stream, MediaStreamTrack oldTrack,
      MediaStreamTrack newTrack,
      {required String clientId}) async {
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (advancedPeerConnection != null) {
      await advancedPeerConnection.replaceTrack(stream, oldTrack, newTrack);
    }
  }

  PeerConnectionStatus status(String peerId, {String? clientId}) {
    var status = PeerConnectionStatus.none;
    if (clientId == null) {
      var advancedPeerConnections = get(peerId);
      for (var advancedPeerConnection in advancedPeerConnections) {
        if (advancedPeerConnection.status == PeerConnectionStatus.connected) {
          status = PeerConnectionStatus.connected;
          break;
        }
      }
    } else {
      AdvancedPeerConnection? advancedPeerConnection =
          peerConnectionPool.getOne(peerId, clientId: clientId);
      if (advancedPeerConnection != null) {
        status = advancedPeerConnection.status;
      }
    }

    return status;
  }
}

final PeerConnectionPool peerConnectionPool = PeerConnectionPool();
