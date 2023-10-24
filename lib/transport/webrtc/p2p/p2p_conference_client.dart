import 'dart:async';

import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/p2p/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:synchronized/synchronized.dart';

class P2pConferencePeerConnection {
  AdvancedPeerConnection peerConnection;

  P2pConferencePeerConnection(this.peerConnection);
}

///视频会议客户端，代表一个正在进行的视频会议，
///包含一个必须的视频会议消息控制器和一个会议内的所有的webrtc连接及其包含的远程视频，
///这些连接与自己正在视频通话
class P2pConferenceClient extends PeerMediaStreamController {
  final Key key = UniqueKey();

  // 参与者的webrtc连接，如果连接为null，说明加入会议，但是连接还没有建立
  final Map<String, Set<String>> _participants = {};

  // 参与者的webrtc连接的订阅事件
  final Map<String, List<StreamSubscription<WebrtcEvent>>>
      _streamSubscriptions = {};

  //自己是否加入
  bool _joined = false;

  //会议的视频消息控制器，是创建会议的邀请消息，包含会议的信息
  final ConferenceChatMessageController conferenceChatMessageController;

  P2pConferenceClient({required this.conferenceChatMessageController});

  /// 获取本会议的所有连接
  Future<List<AdvancedPeerConnection>> get peerConnections async {
    List<AdvancedPeerConnection> peerConnections = [];
    for (MapEntry<String, Set<String>> entry in _participants.entries) {
      String peerId = entry.key;
      Set<String> clientIds = entry.value;
      for (String clientId in clientIds) {
        AdvancedPeerConnection? pc =
            await peerConnectionPool.getOne(peerId, clientId: clientId);
        if (pc != null) {
          peerConnections.add(pc);
        }
      }
    }
    return peerConnections;
  }

  /// 会议中是否存在的对应的participant
  bool contains(String peerId, String clientId) {
    if (_participants.containsKey(peerId)) {
      Set<String>? clientIds = _participants[peerId];
      if (clientIds != null && clientIds.contains(clientId)) {
        return true;
      }
    }
    return false;
  }

  /// 获取会议中存在的对应的连接
  Future<AdvancedPeerConnection?> getAdvancedPeerConnection(
      String peerId, String clientId) async {
    if (_participants.containsKey(peerId)) {
      Set<String>? clientIds = _participants[peerId];
      if (clientIds != null && clientIds.contains(clientId)) {
        return await peerConnectionPool.getOne(peerId, clientId: clientId);
      }
    }
    return null;
  }

  String _getKey(String peerId, String clientId) {
    var key = '$peerId:$clientId';
    return key;
  }

  bool get joined {
    return _joined;
  }

  /// 自己加入会议，在所有的连接中加上本地流
  join() async {
    _joined = true;
    List<AdvancedPeerConnection> pcs = await peerConnections;
    for (AdvancedPeerConnection peerConnection in pcs) {
      await addAdvancedPeerConnection(peerConnection);
    }
  }

  renegotiate(
      {AdvancedPeerConnection? peerConnection, bool toggle = false}) async {
    if (peerConnection != null) {
      await peerConnection.renegotiate(toggle: toggle);
    } else {
      List<AdvancedPeerConnection> pcs = await peerConnections;
      for (AdvancedPeerConnection peerConnection in pcs) {
        await peerConnection.renegotiate(toggle: toggle);
      }
    }
  }

  ///自己退出会议，从所有的连接中移除本地流和远程流
  exit() async {
    _joined = false;
    await conferenceChatMessageController.exit();
    List<AdvancedPeerConnection> pcs = await peerConnections;
    for (AdvancedPeerConnection peerConnection in pcs) {
      await _removeRemotePeerMediaStream(peerConnection);
      List<PeerMediaStream> peerMediaStreams =
          localPeerMediaStreamController.peerMediaStreams;
      if (peerMediaStreams.isNotEmpty) {
        await removeLocalPeerMediaStream(peerMediaStreams,
            peerConnection: peerConnection);
      }
    }
  }

  ///生成并且加入连接的远程视频stream，确保之前连接已经加入
  ///激活add事件
  _addRemotePeerMediaStream(AdvancedPeerConnection peerConnection) async {
    var peerId = peerConnection.peerId;
    var clientId = peerConnection.clientId;
    var name = peerConnection.name;
    RTCPeerConnection? conn = peerConnection.basePeerConnection.peerConnection;
    if (conn == null) {
      return;
    }
    List<MediaStream?> remoteStreams = conn.getRemoteStreams();
    for (var stream in remoteStreams) {
      if (stream == null) {
        logger.e('A peerConnection remoteStream is null');
        continue;
      }
      await _onAddRemoteStream(stream, peerId, clientId, name);
      logger.i(
          'A peerConnection remoteStream video stream ${stream.id} is added');
    }
  }

  ///把本地新的peerMediaStream加入到指定连接或者会议的所有连接中，并且都重新协商
  ///指定连接用在加入新的连接的时候，所有连接用在加入新的peerMediaStream的时候
  addLocalPeerMediaStream(List<PeerMediaStream> peerMediaStreams,
      {AdvancedPeerConnection? peerConnection}) async {
    if (_joined) {
      if (peerConnection != null) {
        for (var peerMediaStream in peerMediaStreams) {
          await peerConnection.addLocalStream(peerMediaStream);
        }
        await renegotiate(peerConnection: peerConnection, toggle: true);
      } else {
        List<AdvancedPeerConnection> pcs = await peerConnections;
        for (AdvancedPeerConnection peerConnection in pcs) {
          for (var peerMediaStream in peerMediaStreams) {
            await peerConnection.addLocalStream(peerMediaStream);
          }
          await renegotiate(peerConnection: peerConnection, toggle: true);
        }
      }
    }
  }

  /// 对方加入会议
  addParticipant(String peerId, String clientId) {
    Set<String>? clientIds = _participants[peerId];
    if (clientIds != null) {
      if (!clientIds.contains(clientId)) {
        clientIds.add(clientId);
      }
    } else {
      clientIds = {clientId};
      _participants[peerId] = clientIds;
    }
  }

  /// 对方已经加入会议，但是连接建立了
  updateAdvancedPeerConnection(AdvancedPeerConnection peerConnection) async {
    bool exist = contains(peerConnection.peerId, peerConnection.clientId);
    if (exist) {
      await addAdvancedPeerConnection(peerConnection);
    }
  }

  ///对方连接加入会议，此连接将与自己展开视频通话
  ///如果自己已经加入，将加入本地流
  addAdvancedPeerConnection(AdvancedPeerConnection peerConnection) async {
    bool exist = contains(peerConnection.peerId, peerConnection.clientId);
    if (!exist) {
      addParticipant(peerConnection.peerId, peerConnection.clientId);
    }
    //只有自己已经加入，才需要加本地流和远程流
    if (_joined) {
      if (!_streamSubscriptions.containsKey(key)) {
        List<StreamSubscription<WebrtcEvent>> streamSubscriptions = [];
        StreamSubscription<WebrtcEvent>? trackStreamSubscription =
            peerConnection.listen(WebrtcEventType.track, _onAddRemoteTrack);
        if (trackStreamSubscription != null) {
          streamSubscriptions.add(trackStreamSubscription);
        }
        StreamSubscription<WebrtcEvent>? removeTrackStreamSubscription =
            peerConnection.listen(
                WebrtcEventType.removeTrack, _onRemoveRemoteTrack);
        if (removeTrackStreamSubscription != null) {
          streamSubscriptions.add(removeTrackStreamSubscription);
        }
        StreamSubscription<WebrtcEvent>? closedStreamSubscription =
            peerConnection.listen(WebrtcEventType.closed, _onClosed);
        if (closedStreamSubscription != null) {
          streamSubscriptions.add(closedStreamSubscription);
        }
        String key = _getKey(peerConnection.peerId, peerConnection.clientId);
        _streamSubscriptions[key] = streamSubscriptions;
      }

      List<PeerMediaStream> peerMediaStreams =
          localPeerMediaStreamController.peerMediaStreams;
      if (peerMediaStreams.isNotEmpty) {
        await addLocalPeerMediaStream(peerMediaStreams,
            peerConnection: peerConnection);
      }

      await _addRemotePeerMediaStream(peerConnection);
    }
  }

  ///移除连接的远程视频
  _removeRemotePeerMediaStream(AdvancedPeerConnection peerConnection) async {
    var peerId = peerConnection.peerId;
    var clientId = peerConnection.clientId;
    List<PeerMediaStream> peerMediaStreams =
        getPeerMediaStreams(peerId, clientId: clientId);
    if (peerMediaStreams.isNotEmpty) {
      for (var peerMediaStream in peerMediaStreams) {
        await close(peerMediaStream);
      }
    }
  }

  ///从会议的指定连接或者所有连接中移除local peerMediaStream，并且都重新协商
  removeLocalPeerMediaStream(List<PeerMediaStream> peerMediaStreams,
      {AdvancedPeerConnection? peerConnection}) async {
    if (peerConnection != null) {
      for (var peerMediaStream in peerMediaStreams) {
        await peerConnection.removeStream(peerMediaStream);
      }
      await renegotiate(peerConnection: peerConnection);
    } else {
      List<AdvancedPeerConnection> pcs = await peerConnections;
      for (AdvancedPeerConnection peerConnection in pcs) {
        for (var peerMediaStream in peerMediaStreams) {
          await peerConnection.removeStream(peerMediaStream);
        }
        await renegotiate(peerConnection: peerConnection);
      }
    }
  }

  /// 对方退出会议
  removeParticipant(String peerId, String clientId) async {
    if (_participants.containsKey(peerId)) {
      Set<String>? clientIds = _participants[peerId];
      if (clientIds != null && clientIds.contains(clientId)) {
        AdvancedPeerConnection? advancedPeerConnection =
            await peerConnectionPool.getOne(peerId, clientId: clientId);
        if (advancedPeerConnection != null) {
          _removeAdvancedPeerConnection(advancedPeerConnection);
        }
        clientIds.remove(clientId);
        if (clientIds.isEmpty) {
          _participants.remove(peerId);
        }
      }
    }
  }

  ///对方退出会议，移除指定连接
  ///把指定连接中的本地媒体关闭并且移除
  _removeAdvancedPeerConnection(AdvancedPeerConnection peerConnection) async {
    var key = _getKey(peerConnection.peerId, peerConnection.clientId);
    List<StreamSubscription<WebrtcEvent>>? streamSubscriptions =
        _streamSubscriptions[key];
    if (streamSubscriptions != null) {
      for (StreamSubscription<WebrtcEvent> streamSubscription
          in streamSubscriptions) {
        streamSubscription.cancel();
      }
      _streamSubscriptions.remove(key);
    }
    if (_joined) {
      await _removeRemotePeerMediaStream(peerConnection);
      List<PeerMediaStream> peerMediaStreams =
          localPeerMediaStreamController.peerMediaStreams;
      if (peerMediaStreams.isNotEmpty) {
        await removeLocalPeerMediaStream(peerMediaStreams,
            peerConnection: peerConnection);
      }
    }
  }

  ///webrtc连接被关闭时，移除连接
  Future<void> _onClosed(WebrtcEvent webrtcEvent) async {
    AdvancedPeerConnection peerConnection = webrtcEvent.data;
    await _removeAdvancedPeerConnection(peerConnection);
  }

  ///远程流到来渲染流，激活add事件
  Future<void> _onAddRemoteTrack(WebrtcEvent webrtcEvent) async {
    Map<String, dynamic> data = webrtcEvent.data;
    MediaStream? stream = data['stream'];
    String peerId = webrtcEvent.peerId;
    String clientId = webrtcEvent.clientId;
    String name = webrtcEvent.name;
    if (stream != null) {
      await _onAddRemoteStream(stream, peerId, clientId, name);
    } else {
      logger.e('onAddRemoteTrack stream is null');
    }
  }

  Future<void> _onAddRemoteStream(
      MediaStream stream, String peerId, String clientId, String name) async {
    String streamId = stream.id;
    PeerMediaStream? peerMediaStream = await getPeerMediaStream(streamId);
    if (peerMediaStream != null) {
      return;
    }
    peerMediaStream = PeerMediaStream();
    await peerMediaStream.buildMediaStream(stream, peerId,
        clientId: clientId, name: name);
    add(peerMediaStream);
  }

  ///远程关闭流事件触发，激活remove事件
  Future<void> _onRemoveRemoteTrack(WebrtcEvent webrtcEvent) async {
    Map<String, dynamic> data = webrtcEvent.data;
    MediaStream? stream = data['stream'];
    if (stream != null) {
      PeerMediaStream? peerMediaStream = await getPeerMediaStream(stream.id);
      if (peerMediaStream != null) {
        var mediaStream = peerMediaStream.mediaStream;
        if (mediaStream != null) {
          await close(peerMediaStream);
        }
      }
    } else {
      logger.e('onAddRemoteTrack stream is null');
    }
  }

  ///终止会议，移除所有的webrtc连接
  ///激活exit事件
  terminate() async {
    currentPeerMediaStream = null;
    mainPeerMediaStream = null;
    if (conferenceChatMessageController.conferenceId != null) {
      conferenceService.update({'status': EntityStatus.expired.name},
          where: 'conferenceId=?',
          whereArgs: [conferenceChatMessageController.conferenceId!]);
    }
    await exit();
    _participants.clear();
    peerMediaStreams.clear();
    conferenceChatMessageController.terminate();
    await onPeerMediaStreamOperator(
        PeerMediaStreamOperator.terminate.name, null);
  }
}

///所有的正在视频会议的池，包含多个视频会议，每个会议的会议号是视频通话邀请的消息号
class P2pConferenceClientPool with ChangeNotifier {
  final Map<String, P2pConferenceClient> _p2pConferenceClients = {};

  final Lock _clientLock = Lock();

  //当前会议编号
  String? _conferenceId;

  P2pConferenceClientPool();

  List<P2pConferenceClient> get p2pConferenceClients {
    return [..._p2pConferenceClients.values];
  }

  ///根据当前的视频邀请消息，查找或者创建当前消息对应的会议，并设置为当前会议
  ///在发起者接收到至少一个同意回执，开始重新协商，或者接收者发送出同意回执的时候调用
  Future<P2pConferenceClient?> createP2pConferenceClient(
      ChatMessage chatMessage,
      {ChatSummary? chatSummary}) async {
    return await _clientLock.synchronized(() async {
      P2pConferenceClient? p2pConferenceClient;
      //创建基于当前聊天的视频消息控制器
      if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
        String conferenceId = chatMessage.messageId!;
        p2pConferenceClient = _p2pConferenceClients[conferenceId];
        if (p2pConferenceClient == null) {
          ConferenceChatMessageController conferenceChatMessageController =
              ConferenceChatMessageController();
          await conferenceChatMessageController.setChatMessage(chatMessage,
              chatSummary: chatSummary);
          p2pConferenceClient = P2pConferenceClient(
              conferenceChatMessageController: conferenceChatMessageController);
          _p2pConferenceClients[conferenceId] = p2pConferenceClient;
        } else {
          ConferenceChatMessageController conferenceChatMessageController =
              p2pConferenceClient.conferenceChatMessageController;
          if (conferenceChatMessageController.chatMessage == null) {
            await conferenceChatMessageController.setChatMessage(chatMessage,
                chatSummary: chatSummary);
          }
        }
        this.conferenceId = conferenceId;

        return p2pConferenceClient;
      }

      return p2pConferenceClient;
    });
  }

  ///获取当前会议号
  String? get conferenceId {
    return _conferenceId;
  }

  ///设置当前会议号
  set conferenceId(String? conferenceId) {
    if (_conferenceId != conferenceId) {
      if (conferenceId != null) {
        if (_p2pConferenceClients.containsKey(conferenceId)) {
          _conferenceId = conferenceId;
        } else {
          _conferenceId = null;
        }
      } else {
        _conferenceId = conferenceId;
      }
      notifyListeners();
    }
  }

  ///获取当前的会议
  P2pConferenceClient? get p2pConferenceClient {
    if (_conferenceId != null) {
      return _p2pConferenceClients[_conferenceId];
    }
    return null;
  }

  ///获取当前会议控制器
  ConferenceChatMessageController? get conferenceChatMessageController {
    if (_conferenceId != null) {
      return _p2pConferenceClients[_conferenceId]
          ?.conferenceChatMessageController;
    }
    return null;
  }

  ///根据会议号返回会议控制器，没有则返回null
  P2pConferenceClient? getP2pConferenceClient(String conferenceId) {
    return _p2pConferenceClients[conferenceId];
  }

  ConferenceChatMessageController? getConferenceChatMessageController(
      String conferenceId) {
    return getP2pConferenceClient(conferenceId)
        ?.conferenceChatMessageController;
  }

  Conference? getConference(String conferenceId) {
    return getP2pConferenceClient(conferenceId)
        ?.conferenceChatMessageController
        .conference;
  }

  /// 新的连接建立事件，如果各会议的连接中存在已经加入但是连接为建立的情况则更新连接
  onConnected(AdvancedPeerConnection peerConnection) async {
    for (P2pConferenceClient p2pConferenceClient
        in _p2pConferenceClients.values) {
      await p2pConferenceClient.updateAdvancedPeerConnection(peerConnection);
    }
  }

  ///把本地新的peerMediaStream加入到会议的所有连接中，并且都重新协商
  addLocalPeerMediaStream(
      String conferenceId, List<PeerMediaStream> peerMediaStreams,
      {AdvancedPeerConnection? peerConnection}) async {
    P2pConferenceClient? p2pConferenceClient =
        _p2pConferenceClients[conferenceId];
    if (p2pConferenceClient != null) {
      await p2pConferenceClient.addLocalPeerMediaStream(peerMediaStreams,
          peerConnection: peerConnection);
    }
  }

  ///会议的指定连接或者所有连接中移除本地或者远程的peerMediaStream，并且都重新协商
  removeLocalPeerMediaStream(
      String conferenceId, List<PeerMediaStream> peerMediaStreams,
      {AdvancedPeerConnection? peerConnection}) async {
    P2pConferenceClient? p2pConferenceClient =
        _p2pConferenceClients[conferenceId];
    if (p2pConferenceClient != null) {
      await p2pConferenceClient.removeLocalPeerMediaStream(peerMediaStreams,
          peerConnection: peerConnection);
    }
  }

  ///根据会议编号退出会议
  ///调用对应会议的退出方法
  exit(String conferenceId) async {
    await _clientLock.synchronized(() async {
      P2pConferenceClient? p2pConferenceClient =
          _p2pConferenceClients[conferenceId];
      if (p2pConferenceClient != null) {
        await p2pConferenceClient.exit();
        if (conferenceId == _conferenceId) {
          _conferenceId = null;
        }
        notifyListeners();
      }
    });
  }

  ///根据会议编号终止会议
  ///调用对应会议的终止方法，然后从会议池中删除，设置当前会议编号为null
  terminate(String conferenceId) async {
    await _clientLock.synchronized(() async {
      P2pConferenceClient? p2pConferenceClient =
          _p2pConferenceClients[conferenceId];
      if (p2pConferenceClient != null) {
        await p2pConferenceClient.terminate();
        _p2pConferenceClients.remove(conferenceId);
        if (conferenceId == _conferenceId) {
          _conferenceId = null;
        }
        notifyListeners();
      }
    });
  }
}

///存放已经开始的会议，就是发起者接收到至少一个同意回执，开始重新协商，或者接收者发送出同意回执
final P2pConferenceClientPool p2pConferenceClientPool =
    P2pConferenceClientPool();
