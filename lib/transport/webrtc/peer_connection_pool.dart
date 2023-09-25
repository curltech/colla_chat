import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/crypto/signalprotocol.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/action/signal.dart';
import 'package:colla_chat/pages/chat/index/global_chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:synchronized/synchronized.dart';

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
  Duration clearDuration = const Duration(seconds: 20);

  ///自己的peerId,clientId和公钥
  late String peerId;
  late String clientId;
  late SimplePublicKey peerPublicKey;

  ///对方的队列，每一个peerId的元素是一个列表，具有相同的peerId和不同的clientId
  final LruQueue<Map<String, AdvancedPeerConnection>> _peerConnections =
      LruQueue();

  final Lock _connLock = Lock();

  PeerConnectionPool() {
    signalAction.receiveStreamController.stream
        .listen((ChainMessage chainMessage) {
      onSignal(chainMessage);
    });

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
    Timer.periodic(clearDuration, (Timer timer) {
      clear();
    });
  }

  /// 获取peerId的webrtc连接，可能是多个
  /// @param peerId
  Future<List<AdvancedPeerConnection>> get(String peerId) async {
    return _get(peerId);
  }

  List<AdvancedPeerConnection> _get(String peerId) {
    if (_peerConnections.containsKey(peerId)) {
      Map<String, AdvancedPeerConnection>? aps = _peerConnections.use(peerId);
      if (aps != null) {
        return aps.values.toList();
      }
    }

    return [];
  }

  Future<AdvancedPeerConnection?> getOne(String peerId,
      {required String clientId}) async {
    return _getOne(peerId, clientId: clientId);
  }

  AdvancedPeerConnection? _getOne(String peerId, {required String clientId}) {
    if (_peerConnections.containsKey(peerId)) {
      Map<String, AdvancedPeerConnection>? aps = _peerConnections.use(peerId);
      if (aps != null && aps.isNotEmpty) {
        return aps[clientId];
      }
    }

    return null;
  }

  put(
    String peerId,
    AdvancedPeerConnection advancedPeerConnection, {
    String clientId = unknownClientId,
  }) {
    var peerConnections = _peerConnections.get(peerId);
    peerConnections = peerConnections ?? {};
    AdvancedPeerConnection? old = peerConnections[clientId];
    if (old != null) {
      logger.w('old peerId:$peerId clientId:$clientId is exist!');
    }
    peerConnections[clientId] = advancedPeerConnection;

    ///如果有溢出的连接，将溢出连接关闭
    Map<String, AdvancedPeerConnection>? outs =
        _peerConnections.put(peerId, peerConnections);
    if (outs != null && outs.isNotEmpty) {
      for (AdvancedPeerConnection out in outs.values) {
        logger.e('over max webrtc peer number, knocked out');
        out.close();
      }
    }
  }

  ///主动方创建，此时clientId有可能不知道，如果已经存在，先关闭删除
  Future<AdvancedPeerConnection?> createOffer(String peerId,
      {String clientId = unknownClientId,
      Conference? conference,
      List<Map<String, String>>? iceServers,
      List<PeerMediaStream> localRenders = const []}) async {
    AdvancedPeerConnection? peerConnection =
        await _connLock.synchronized(() async {
      AdvancedPeerConnection? peerConnection =
          _getOne(peerId, clientId: clientId);
      if (peerConnection != null) {
        logger.e('peerId:$peerId clientId:$clientId is exist!');
        return null;
      }
      //创建新的主叫方
      peerConnection = AdvancedPeerConnection(peerId, clientId: clientId);
      bool result = await peerConnection.init(true,
          iceServers: iceServers, localPeerMediaStreams: localRenders);
      if (!result) {
        logger.e('webrtcPeer.init fail');
        return null;
      }

      await put(peerId, peerConnection, clientId: clientId);

      ///在启动协商
      await peerConnection.renegotiate();

      return peerConnection;
    });

    if (peerConnection != null) {
      String name = unknownName;
      Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
      if (linkman != null) {
        name = linkman.name;
      }

      ///created事件加入流
      StreamController<WebrtcEvent>? createdWebrtcEventStreamController =
          peerConnection.webrtcEventStreamControllers[WebrtcEventType.created];
      if (createdWebrtcEventStreamController != null) {
        createdWebrtcEventStreamController.add(WebrtcEvent(peerId,
            clientId: clientId,
            name: name,
            eventType: WebrtcEventType.created,
            data: peerConnection));
      }
    }
    peerConnection = _getOne(peerId, clientId: clientId);

    return peerConnection;
  }

  ///从池中移除连接，不关心连接的状态
  Map<String, AdvancedPeerConnection>? remove(String peerId,
      {String? clientId}) {
    Map<String, AdvancedPeerConnection>? peerConnections =
        _peerConnections.get(peerId);
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
        logger.w('remove peerConnection peerId:$peerId,clientId:$clientId');
      }
      if (peerConnections.isEmpty) {
        _peerConnections.remove(peerId);
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
        _peerConnections.get(peerId);
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

  Future<List<AdvancedPeerConnection>> getAll() async {
    List<AdvancedPeerConnection> peerConnections = [];
    for (var peers in _peerConnections.all) {
      for (var peer in peers.values) {
        peerConnections.add(peer);
      }
    }
    return peerConnections;
  }

  ///清除过一段时间仍没有连接上的连接
  clear() async {
    List<AdvancedPeerConnection> removedPeerConnections = [];
    for (var peerId in _peerConnections.keys()) {
      Map<String, AdvancedPeerConnection>? peerConnections =
          _peerConnections.get(peerId);
      if (peerConnections != null && peerConnections.isNotEmpty) {
        for (AdvancedPeerConnection peerConnection in peerConnections.values) {
          if (peerConnection.connectionState !=
              RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
            var start = peerConnection.basePeerConnection.start;
            if (start == null) {
              removedPeerConnections.add(peerConnection);
            } else {
              var now = DateTime.now().millisecondsSinceEpoch;
              var gap = now - start;
              var limit = clearDuration;
              if (gap > limit.inMilliseconds) {
                removedPeerConnections.add(peerConnection);
                logger.e(
                    'peerConnection peerId:${peerConnection.peerId},clientId:${peerConnection.clientId} is overtime unconnected');
              }
            }
          }
        }
      }
    }
    for (var removedPeerConnection in removedPeerConnections) {
      await removedPeerConnection.close();
    }
  }

  ///如果不存在，创建被叫，如果存在直接返回
  Future<AdvancedPeerConnection?> createAnswer(String peerId,
      {required String clientId,
      required String name,
      Conference? conference,
      List<Map<String, String>>? iceServers,
      Uint8List? aesKey}) async {
    AdvancedPeerConnection? advancedPeerConnection =
        await _connLock.synchronized(() async {
      AdvancedPeerConnection? advancedPeerConnection =
          _getOne(peerId, clientId: clientId);
      if (advancedPeerConnection == null) {
        logger.i('advancedPeerConnection is null,create new one');
        advancedPeerConnection =
            AdvancedPeerConnection(peerId, clientId: clientId, name: name);
        bool result = await advancedPeerConnection.init(false,
            iceServers: iceServers, aesKey: aesKey);
        if (!result) {
          logger.e('webrtcPeer.init fail');
          return null;
        }
        put(peerId, advancedPeerConnection, clientId: clientId);

        return advancedPeerConnection;
      } else {
        logger.e('peerId:$peerId clientId:$clientId is exist!');
        return null;
      }
    });
    if (advancedPeerConnection != null) {
      ///created事件加入流
      StreamController<WebrtcEvent>? createdWebrtcEventStreamController =
          advancedPeerConnection
              .webrtcEventStreamControllers[WebrtcEventType.created];
      if (createdWebrtcEventStreamController != null) {
        createdWebrtcEventStreamController.add(WebrtcEvent(peerId,
            clientId: clientId,
            name: name,
            eventType: WebrtcEventType.created,
            data: advancedPeerConnection));
      }
      logger.i(
          'advancedPeerConnection ${advancedPeerConnection.basePeerConnection.id} createAnswer completed');
    }

    advancedPeerConnection = _getOne(peerId, clientId: clientId);

    return advancedPeerConnection;
  }

  /// 从信号服务器传来的webrtc的协商消息
  /// 通过监听signalAction的流控制器
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
  onWebrtcSignal(String peerId, WebrtcSignal signal,
      {required String clientId}) async {
    var signalType = signal.signalType;
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

    ///先寻找合适的连接，如果为不存在，则寻找clientId为unknownClientId的连接
    ///存在，表明自己是主叫，建立的时候对方的clientId未知，设置正确的clientId和name
    AdvancedPeerConnection? advancedPeerConnection =
        await _connLock.synchronized(() async {
      AdvancedPeerConnection? advancedPeerConnection =
          _getOne(peerId, clientId: clientId);
      if (advancedPeerConnection == null) {
        advancedPeerConnection = _getOne(peerId, clientId: unknownClientId);
        if (advancedPeerConnection != null) {
          advancedPeerConnection.clientId = clientId;
          advancedPeerConnection.name = name;
          remove(peerId, clientId: unknownClientId);
          put(peerId, advancedPeerConnection, clientId: clientId);
        } else {
          logger.w('no match advancedPeerConnection, signalType:$signalType');
        }
      }
      return advancedPeerConnection;
    });

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
    if (signalType == SignalType.error.name) {
      WebrtcEvent webrtcEvent = WebrtcEvent(peerId,
          clientId: clientId,
          name: name,
          eventType: WebrtcEventType.signal,
          data: signal);
      await globalWebrtcEventController.receiveErrorSignal(webrtcEvent);
    }
    //收到被叫的answer，正常情况下能找到合适的主叫
    // else if ((signalType == SignalType.sdp.name &&
    //     signal.sdp!.type == 'answer')) {
    //   //符合的主叫不存在
    //   if (advancedPeerConnection == null) {
    //     logger.e(
    //         'peerId:$peerId, clientId:$clientId has no offer advancedPeerConnection to match');
    //   }
    //   //符合的主叫存在，但是已经连接上了，可能在重新协商
    //   else if (advancedPeerConnection.status ==
    //       PeerConnectionStatus.connected) {
    //     // logger.e(
    //     //     'peerId:$peerId, clientId:$clientId offer advancedPeerConnection is connected');
    //   }
    // }
    //收到candidate信号或者sdp offer信号的时候，如果连接不存在需要创建新的连接
    else if (signalType == SignalType.candidate.name ||
        (signalType == SignalType.sdp.name && signal.sdp!.type == 'offer')) {
      ///如果连接没有创建，则申请许可是否允许创建被叫连接
      ///对于主叫或者已经创建的被叫来说，不需要申请许可
      if (advancedPeerConnection == null) {
        WebrtcEvent webrtcEvent = WebrtcEvent(peerId,
            clientId: clientId,
            name: name,
            eventType: WebrtcEventType.signal,
            data: signal);
        bool allowed =
            await globalWebrtcEventController.receiveWebrtcSignal(webrtcEvent);
        if (allowed) {
          Uint8List? aesKey = extension?.aesKey;
          advancedPeerConnection = await createAnswer(peerId,
              clientId: clientId,
              name: name,
              conference: conference,
              iceServers: iceServers,
              aesKey: aesKey);
          if (advancedPeerConnection == null) {
            logger.e('createAnswer fail');
            return null;
          }
        } else {
          String error = 'peerId:$peerId can not receive a webrtc connection';
          logger.e(error);
          WebrtcSignal webrtcSignal =
              WebrtcSignal(SignalType.error.name, error: error);
          if (advancedPeerConnection != null) {
            await advancedPeerConnection.sendSignal(webrtcSignal);
          }

          return null;
        }
      }
    }

    ///转发信号到base层处理，包括renegotiate
    if (advancedPeerConnection != null) {
      await advancedPeerConnection.basePeerConnection.onSignal(signal);
    }
  }

  /// 向peer发送信息，如果是多个，遍历发送
  Future<bool> send(String peerId, List<int> data) async {
    List<AdvancedPeerConnection> peerConnections = _get(peerId);
    if (peerConnections.isNotEmpty) {
      List<Future<bool>> ps = [];
      for (var peerConnection in peerConnections) {
        if (peerConnection.dataChannelOpen &&
            peerConnection.basePeerConnection.dataChannel != null) {
          Future<bool> p = peerConnection.send(data);
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
      if (peerId == myself.peerId) {
        logger.i('Target $peerId,clientId;$clientId is myself, cannot send');
      } else {
        logger.e(
            'PeerConnection:$peerId,clientId;$clientId is not exist, cannot send');
      }
    }
    return false;
  }



  removeTrack(String peerId, MediaStream stream, MediaStreamTrack track,
      {required String clientId}) async {
    AdvancedPeerConnection? advancedPeerConnection =
        await peerConnectionPool.getOne(peerId, clientId: clientId);
    if (advancedPeerConnection != null) {
      await advancedPeerConnection.removeTrack(stream, track);
    }
  }

  replaceTrack(String peerId, MediaStream stream, MediaStreamTrack oldTrack,
      MediaStreamTrack newTrack,
      {required String clientId}) async {
    AdvancedPeerConnection? advancedPeerConnection =
        await peerConnectionPool.getOne(peerId, clientId: clientId);
    if (advancedPeerConnection != null) {
      await advancedPeerConnection.replaceTrack(stream, oldTrack, newTrack);
    }
  }

  ///获取连接状态
  RTCPeerConnectionState? connectionState(String peerId, {String? clientId}) {
    RTCPeerConnectionState? state;
    if (clientId == null) {
      var advancedPeerConnections = _get(peerId);
      for (var advancedPeerConnection in advancedPeerConnections) {
        if (advancedPeerConnection.connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          state = RTCPeerConnectionState.RTCPeerConnectionStateConnected;
          break;
        }
      }
    } else {
      AdvancedPeerConnection? advancedPeerConnection =
          _getOne(peerId, clientId: clientId);
      if (advancedPeerConnection != null) {
        state = advancedPeerConnection.connectionState;
      }
    }

    return state;
  }
}

final PeerConnectionPool peerConnectionPool = PeerConnectionPool();
