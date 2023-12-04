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
import 'package:colla_chat/transport/webrtc/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:synchronized/synchronized.dart';

///视频会议客户端，代表一个正在进行的视频会议，
///包含一个必须的视频会议消息控制器和一个会议内的所有的webrtc连接及其包含的远程视频，
///这些连接与自己正在视频通话
class P2pConferenceClient {
  final Key key = UniqueKey();

  PeerMediaStreamController remotePeerMediaStreamController =
      PeerMediaStreamController();

  // 参与者的webrtc连接，如果连接为null，说明加入会议，但是连接还没有建立
  final Map<String, PlatformParticipant> _remoteParticipants = {};

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
    for (MapEntry<String, PlatformParticipant> entry
        in _remoteParticipants.entries) {
      String key = entry.key;
      PlatformParticipant platformParticipant = entry.value;
      AdvancedPeerConnection? pc = await peerConnectionPool.getOne(
          platformParticipant.peerId,
          clientId: platformParticipant.clientId!);
      if (pc != null) {
        peerConnections.add(pc);
      }
    }
    return peerConnections;
  }

  String _getKey(String peerId, String clientId) {
    var key = '$peerId:$clientId';
    return key;
  }

  bool get joined {
    return _joined;
  }

  Map<String, PlatformParticipant> remoteParticipants() {
    return _remoteParticipants;
  }

  /// 自己加入会议，在所有的连接中加上本地流
  join() async {
    Conference? conference = conferenceChatMessageController.conference;
    if (conference == null) {
      return;
    }
    bool isValid = conferenceService.isValid(conference);
    if (!isValid) {
      logger.e('conference ${conference.name} is invalid');
      return;
    }
    _joined = true;
    logger.w('i joined conference ${conference.name}');
    List<AdvancedPeerConnection> pcs = await peerConnections;
    for (AdvancedPeerConnection peerConnection in pcs) {
      await _onParticipantConnected(peerConnection);
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

  /// 发布本地视频或者音频，如果参数的流为null，则创建本地主视频并发布
  /// 把本地新的peerMediaStream加入到会议的所有连接中，并且都重新协商
  publish({List<PeerMediaStream>? peerMediaStreams}) async {
    if (!joined) {
      return;
    }
    if (peerMediaStreams == null) {
      PeerMediaStream peerMediaStream;
      bool? video = conferenceChatMessageController.conference?.video;
      if (video != null && video) {
        peerMediaStream = await PeerMediaStream.createLocalVideoMedia();
      } else {
        peerMediaStream = await PeerMediaStream.createLocalAudioMedia();
      }
      peerMediaStreams = [peerMediaStream];
      localPeerMediaStreamController.mainPeerMediaStream = peerMediaStream;
    }
    List<AdvancedPeerConnection> pcs = await peerConnections;
    for (AdvancedPeerConnection peerConnection in pcs) {
      for (var peerMediaStream in peerMediaStreams) {
        await peerConnection.addLocalStream(peerMediaStream);
      }
      await renegotiate(peerConnection: peerConnection, toggle: true);
    }
  }

  /// 从会议的所有连接中退出发布并且关闭本地的多个视频流，并且都重新协商
  close(List<PeerMediaStream> peerMediaStreams) async {
    if (joined) {
      List<AdvancedPeerConnection> pcs = await peerConnections;
      for (AdvancedPeerConnection peerConnection in pcs) {
        for (PeerMediaStream peerMediaStream in peerMediaStreams) {
          await peerConnection.removeStream(peerMediaStream);

          if (peerMediaStream.id != null) {
            await localPeerMediaStreamController.close(peerMediaStream.id!);
          }
        }
        await renegotiate(peerConnection: peerConnection);
      }
    }
  }

  /// 退出发布并且关闭本地的所有的轨道或者流
  closeAll({bool notify = true}) async {
    close(localPeerMediaStreamController.peerMediaStreams);
  }

  /// 远程参与者加入会议事件，此时连接未必已经建立
  /// 如果连接建立，则加入连接
  onParticipantConnectedEvent(PlatformParticipant platformParticipant) async {
    var peerId = platformParticipant.peerId;
    var clientId = platformParticipant.clientId!;
    var key = _getKey(peerId, clientId);
    var name = platformParticipant.name;
    if (!_remoteParticipants.containsKey(key)) {
      _remoteParticipants[key] = platformParticipant;
      logger.w(
          '$key joined conference ${conferenceChatMessageController.conference?.name}');
    }
    AdvancedPeerConnection? advancedPeerConnection =
        await peerConnectionPool.getOne(
      peerId,
      clientId: clientId,
    );
    if (advancedPeerConnection != null) {
      await _onParticipantConnected(advancedPeerConnection);
    }
  }

  /// 远程参与者的连接加入会议操作，此连接将与自己展开视频通话
  /// 如果自己已经加入，将在各远程连接中加入本地流
  _onParticipantConnected(AdvancedPeerConnection peerConnection) async {
    String peerId = peerConnection.peerId;
    String clientId = peerConnection.clientId;
    String name = peerConnection.name;
    var key = _getKey(peerId, clientId);
    if (!_remoteParticipants.containsKey(key)) {
      _remoteParticipants[key] =
          PlatformParticipant(peerId, clientId: clientId, name: name);
      logger.w(
          '$key joined conference ${conferenceChatMessageController.conference?.name}');
    }
    // 只有自己已经加入，才需要加本地流和远程流
    if (_joined) {
      if (!_streamSubscriptions.containsKey(key)) {
        List<StreamSubscription<WebrtcEvent>> streamSubscriptions = [];
        StreamSubscription<WebrtcEvent>? trackStreamSubscription =
            peerConnection.listen(
                WebrtcEventType.track, _onTrackPublishedEvent);
        if (trackStreamSubscription != null) {
          streamSubscriptions.add(trackStreamSubscription);
        }
        StreamSubscription<WebrtcEvent>? removeTrackStreamSubscription =
            peerConnection.listen(
                WebrtcEventType.removeTrack, _onTrackUnpublishedEvent);
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
        for (var peerMediaStream in peerMediaStreams) {
          await peerConnection.addLocalStream(peerMediaStream);
        }
        await renegotiate(peerConnection: peerConnection, toggle: true);
      }

      await _onStreamPublished(peerConnection);
    }
  }

  /// 生成并且加入连接的远程视频stream，确保之前连接已经加入
  _onStreamPublished(AdvancedPeerConnection peerConnection) async {
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
      PlatformParticipant platformParticipant =
          PlatformParticipant(peerId, clientId: clientId, name: name);
      await _onStreamPublishedEvent(stream, platformParticipant);
      logger.i(
          'A peerConnection remoteStream video stream ${stream.id} is added');
    }
  }

  /// 远程参与者退出会议
  onParticipantDisconnectedEvent(
      PlatformParticipant platformParticipant) async {
    String peerId = platformParticipant.peerId;
    String clientId = platformParticipant.clientId!;
    var key = _getKey(peerId, clientId);
    if (_remoteParticipants.containsKey(key)) {
      AdvancedPeerConnection? advancedPeerConnection =
          await peerConnectionPool.getOne(peerId, clientId: clientId);
      if (advancedPeerConnection != null) {
        _onParticipantDisconnected(advancedPeerConnection);
      }
      _remoteParticipants.remove(key);
    }
  }

  /// 远程参与者退出会议操作，移除指定连接
  /// 把指定连接中的本地媒体全部移除并且重新协商
  _onParticipantDisconnected(AdvancedPeerConnection peerConnection) async {
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
    await _onParticipantUnpublish(peerConnection);
    List<PeerMediaStream> peerMediaStreams =
        localPeerMediaStreamController.peerMediaStreams;
    if (peerMediaStreams.isNotEmpty) {
      for (PeerMediaStream peerMediaStream in peerMediaStreams) {
        await peerConnection.removeStream(peerMediaStream);
      }
      await renegotiate(peerConnection: peerConnection);
    }
  }

  /// 从远程视频流的控制器中移除连接的远程视频操作
  _onParticipantUnpublish(AdvancedPeerConnection peerConnection) async {
    var peerId = peerConnection.peerId;
    var clientId = peerConnection.clientId;
    List<PeerMediaStream> peerMediaStreams = remotePeerMediaStreamController
        .getPeerMediaStreams(peerId, clientId: clientId);
    if (peerMediaStreams.isNotEmpty) {
      for (var peerMediaStream in peerMediaStreams) {
        await remotePeerMediaStreamController.close(peerMediaStream.id!);
      }
    }
  }

  /// 远程流到来渲染流，激活add事件
  Future<void> _onTrackPublishedEvent(WebrtcEvent webrtcEvent) async {
    Map<String, dynamic> data = webrtcEvent.data;
    MediaStream? stream = data['stream'];
    String peerId = webrtcEvent.peerId;
    String clientId = webrtcEvent.clientId;
    String name = webrtcEvent.name;
    PlatformParticipant platformParticipant =
        PlatformParticipant(peerId, clientId: clientId, name: name);
    if (stream != null) {
      await _onStreamPublishedEvent(stream, platformParticipant);
    } else {
      logger.e('onAddRemoteTrack stream is null');
    }
  }

  /// 加入新的远程流
  Future<void> _onStreamPublishedEvent(
      MediaStream stream, PlatformParticipant platformParticipant) async {
    String streamId = stream.id;
    PeerMediaStream? peerMediaStream =
        await remotePeerMediaStreamController.getPeerMediaStream(streamId);
    if (peerMediaStream != null) {
      return;
    }
    peerMediaStream = await PeerMediaStream.createPeerMediaStream(
        platformParticipant: platformParticipant, mediaStream: stream);
    remotePeerMediaStreamController.add(peerMediaStream);
  }

  /// 远程关闭流事件触发，激活remove事件
  Future<void> _onTrackUnpublishedEvent(WebrtcEvent webrtcEvent) async {
    Map<String, dynamic> data = webrtcEvent.data;
    MediaStream? stream = data['stream'];
    if (stream != null) {
      PeerMediaStream? peerMediaStream =
          await remotePeerMediaStreamController.getPeerMediaStream(stream.id);
      if (peerMediaStream != null) {
        await remotePeerMediaStreamController.close(peerMediaStream.id!);
      }
    } else {
      logger.e('onAddRemoteTrack stream is null');
    }
  }

  ///webrtc连接被关闭时，移除连接
  Future<void> _onClosed(WebrtcEvent webrtcEvent) async {
    AdvancedPeerConnection peerConnection = webrtcEvent.data;
    await _onParticipantDisconnected(peerConnection);
  }

  /// 自己退出会议，从所有的连接中移除本地流和远程流
  _disconnect() async {
    _joined = false;
    await conferenceChatMessageController.exit();
    List<PeerMediaStream> peerMediaStreams =
        localPeerMediaStreamController.peerMediaStreams;
    if (peerMediaStreams.isNotEmpty) {
      await close(peerMediaStreams);
    }
    List<AdvancedPeerConnection> pcs = await peerConnections;
    for (AdvancedPeerConnection peerConnection in pcs) {
      await _onParticipantDisconnected(peerConnection);
    }
  }

  ///终止会议，移除所有的webrtc连接
  ///激活exit事件
  terminate() async {
    remotePeerMediaStreamController.currentPeerMediaStream = null;
    if (conferenceChatMessageController.conferenceId != null) {
      conferenceService.update({'status': EntityStatus.expired.name},
          where: 'conferenceId=?',
          whereArgs: [conferenceChatMessageController.conferenceId!]);
    }
    await _disconnect();
    _remoteParticipants.clear();
    remotePeerMediaStreamController.peerMediaStreams.clear();
    conferenceChatMessageController.terminate();
  }
}

///所有的正在视频会议的池，包含多个视频会议，每个会议的会议号是视频通话邀请的消息号
class P2pConferenceClientPool with ChangeNotifier {
  final Map<String, P2pConferenceClient> _conferenceClients = {};

  final Lock _clientLock = Lock();

  //当前会议编号
  String? _conferenceId;

  P2pConferenceClientPool();

  List<P2pConferenceClient> get conferenceClients {
    return [..._conferenceClients.values];
  }

  ///根据当前的视频邀请消息，查找或者创建当前消息对应的会议，并设置为当前会议
  ///在发起者接收到至少一个同意回执，开始重新协商，或者接收者发送出同意回执的时候调用
  Future<P2pConferenceClient?> createConferenceClient(ChatMessage chatMessage,
      {ChatSummary? chatSummary}) async {
    return await _clientLock.synchronized(() async {
      P2pConferenceClient? p2pConferenceClient;
      //创建基于当前聊天的视频消息控制器
      if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
        String conferenceId = chatMessage.messageId!;
        p2pConferenceClient = _conferenceClients[conferenceId];
        if (p2pConferenceClient == null) {
          ConferenceChatMessageController conferenceChatMessageController =
              ConferenceChatMessageController();
          await conferenceChatMessageController.setChatMessage(chatMessage,
              chatSummary: chatSummary);
          p2pConferenceClient = P2pConferenceClient(
              conferenceChatMessageController: conferenceChatMessageController);
          _conferenceClients[conferenceId] = p2pConferenceClient;
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
        if (_conferenceClients.containsKey(conferenceId)) {
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
  P2pConferenceClient? get conferenceClient {
    if (_conferenceId != null) {
      return _conferenceClients[_conferenceId];
    }
    return null;
  }

  ///获取当前会议控制器
  ConferenceChatMessageController? get conferenceChatMessageController {
    if (_conferenceId != null) {
      return _conferenceClients[_conferenceId]?.conferenceChatMessageController;
    }
    return null;
  }

  ///根据会议号返回会议控制器，没有则返回null
  P2pConferenceClient? getConferenceClient(String conferenceId) {
    return _conferenceClients[conferenceId];
  }

  ConferenceChatMessageController? getConferenceChatMessageController(
      String conferenceId) {
    return getConferenceClient(conferenceId)?.conferenceChatMessageController;
  }

  Conference? getConference(String conferenceId) {
    return getConferenceClient(conferenceId)
        ?.conferenceChatMessageController
        .conference;
  }

  /// 新的连接建立事件，如果各会议的连接中存在已经加入但是连接为建立的情况则更新连接
  onConnected(AdvancedPeerConnection peerConnection) async {
    for (P2pConferenceClient p2pConferenceClient in _conferenceClients.values) {
      await p2pConferenceClient._onParticipantConnected(peerConnection);
    }
  }

  ///把本地新的peerMediaStream加入到会议的所有连接中，并且都重新协商
  publish(String conferenceId, List<PeerMediaStream> peerMediaStreams) async {
    P2pConferenceClient? p2pConferenceClient = _conferenceClients[conferenceId];
    if (p2pConferenceClient != null) {
      await p2pConferenceClient.publish(peerMediaStreams: peerMediaStreams);
    }
  }

  ///会议的指定连接或者所有连接中移除本地或者远程的peerMediaStream，并且都重新协商
  close(String conferenceId, List<PeerMediaStream> peerMediaStreams) async {
    P2pConferenceClient? p2pConferenceClient = _conferenceClients[conferenceId];
    if (p2pConferenceClient != null) {
      await p2pConferenceClient.close(peerMediaStreams);
    }
  }

  ///根据会议编号退出会议
  ///调用对应会议的退出方法
  closeAll(String conferenceId) async {
    await _clientLock.synchronized(() async {
      P2pConferenceClient? conferenceClient = _conferenceClients[conferenceId];
      if (conferenceClient != null) {
        await conferenceClient.closeAll();
        notifyListeners();
      }
    });
  }

  /// 根据会议编号退出会议
  /// 调用对应会议的退出方法
  disconnect({String? conferenceId}) async {
    await _clientLock.synchronized(() async {
      conferenceId ??= _conferenceId;
      P2pConferenceClient? p2pConferenceClient =
          _conferenceClients[conferenceId];
      if (p2pConferenceClient != null) {
        await p2pConferenceClient._disconnect();
        if (conferenceId == _conferenceId) {
          _conferenceId = null;
        }
        notifyListeners();
      }
    });
  }

  ///根据会议编号终止会议
  ///调用对应会议的终止方法，然后从会议池中删除，设置当前会议编号为null
  terminate({String? conferenceId}) async {
    await _clientLock.synchronized(() async {
      conferenceId ??= _conferenceId;
      P2pConferenceClient? p2pConferenceClient =
          _conferenceClients[conferenceId];
      if (p2pConferenceClient != null) {
        await p2pConferenceClient.terminate();
        _conferenceClients.remove(conferenceId);
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
