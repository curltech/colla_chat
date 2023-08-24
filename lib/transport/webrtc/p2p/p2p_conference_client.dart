import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/p2p/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

///视频会议客户端，代表一个正在进行的视频会议，
///包含一个必须的视频会议消息控制器和一个会议内的所有的webrtc连接及其包含的远程视频，
///这些连接与自己正在视频通话
class P2pConferenceClient extends PeerMediaStreamController {
  final Key key = UniqueKey();

  //根据peerId和clientId对应的所有的webrtc连接
  final Map<String, AdvancedPeerConnection> _peerConnections = {};

  //会议的视频消息控制器，是创建会议的邀请消息，包含会议的信息
  final ConferenceChatMessageController conferenceChatMessageController;

  P2pConferenceClient({required this.conferenceChatMessageController});

  String _getKey(String peerId, String clientId) {
    var key = '$peerId:$clientId';
    return key;
  }

  ///生成并且加入连接的远程视频stream，确保之前连接已经加入
  ///激活add事件
  _addPeerMediaStream(AdvancedPeerConnection peerConnection) async {
    var peerId = peerConnection.peerId;
    var clientId = peerConnection.clientId;
    var name = peerConnection.name;
    var key = _getKey(peerId, clientId);
    if (!_peerConnections.containsKey(key)) {
      logger.e('PeerConnection of add peerMediaStream is not exist');
    }
    List<MediaStream?> remoteStreams =
        peerConnection.basePeerConnection.peerConnection!.getRemoteStreams();
    if (remoteStreams.isEmpty) {
      logger.e('PeerConnection of add peerMediaStream is no remote stream');
    }
    for (var stream in remoteStreams) {
      if (stream == null) {
        logger.e('A peerConnection remoteStream is null');
        continue;
      }
      PeerMediaStream? peerMediaStream = await getPeerMediaStream(stream.id);
      if (peerMediaStream != null) {
        logger.e('A peerConnection remoteStream video stream is exist');
        continue;
      }
      peerMediaStream = PeerMediaStream();
      await peerMediaStream.buildMediaStream(stream, peerId,
          clientId: clientId, name: name);
      add(peerMediaStream);
      logger.i(
          'A peerConnection remoteStream video stream ${stream.id} is added');
    }
  }

  ///把本地新的peerMediaStream加入到指定连接或者会议的所有连接中，并且都重新协商
  ///指定连接用在加入新的连接的时候，所有连接用在加入新的peerMediaStream的时候
  addLocalPeerMediaStream(List<PeerMediaStream> peerMediaStreams,
      {AdvancedPeerConnection? peerConnection}) async {
    if (peerConnection != null) {
      for (var peerMediaStream in peerMediaStreams) {
        await peerConnection.addLocalStream(peerMediaStream);
      }
      await peerConnection.negotiate();
    } else {
      for (AdvancedPeerConnection peerConnection in _peerConnections.values) {
        for (var peerMediaStream in peerMediaStreams) {
          await peerConnection.addLocalStream(peerMediaStream);
        }
        await peerConnection.negotiate();
      }
    }
  }

  ///将连接加入控制器，此连接将与自己展开视频通话
  addAdvancedPeerConnection(AdvancedPeerConnection peerConnection) async {
    var key = _getKey(peerConnection.peerId, peerConnection.clientId);
    if (!_peerConnections.containsKey(key)) {
      _peerConnections[key] = peerConnection;
      peerConnection.registerWebrtcEvent(
          WebrtcEventType.track, _onAddRemoteTrack);
      peerConnection.registerWebrtcEvent(
          WebrtcEventType.removeTrack, _onRemoveRemoteTrack);
      peerConnection.registerWebrtcEvent(WebrtcEventType.closed, _onClosed);
      await _addPeerMediaStream(peerConnection);
      List<PeerMediaStream> peerMediaStreams =
          localPeerMediaStreamController.peerMediaStreams;
      if (peerMediaStreams.isNotEmpty) {
        await addLocalPeerMediaStream(peerMediaStreams,
            peerConnection: peerConnection);
      }
    }
  }

  ///获取同peerId的所有连接
  List<AdvancedPeerConnection> getAdvancedPeerConnections(String peerId) {
    List<AdvancedPeerConnection> pcs = [];
    for (var pc in _peerConnections.values) {
      if (peerId == pc.peerId) {
        pcs.add(pc);
      }
    }
    return pcs;
  }

  ///获取单一连接，如果返回null表示不存在
  AdvancedPeerConnection? getAdvancedPeerConnection(
      String peerId, String clientId) {
    var key = _getKey(peerId, clientId);
    return _peerConnections[key];
  }

  ///移除连接的远程视频
  _removePeerMediaStream(AdvancedPeerConnection peerConnection) async {
    var peerId = peerConnection.peerId;
    var clientId = peerConnection.clientId;
    var key = _getKey(peerId, clientId);
    if (!_peerConnections.containsKey(key)) {
      logger.e('PeerConnection of remove peerMediaStream is not exist');
    }
    RTCPeerConnection? pc = peerConnection.basePeerConnection.peerConnection;
    if (pc == null) {
      logger.e('RTCPeerConnection of remove peerMediaStream is null');
      return;
    }
    List<MediaStream?> remoteStreams = pc.getRemoteStreams();
    if (remoteStreams.isEmpty) {
      logger.e('PeerConnection of remove peerMediaStream is no remote stream');
      return;
    }
    for (var stream in remoteStreams) {
      if (stream == null) {
        logger.e('A peerConnection remoteStream is null');
        continue;
      }
      PeerMediaStream? peerMediaStream = await getPeerMediaStream(stream.id);
      if (peerMediaStream == null) {
        logger.e('A peerConnection remoteStream video stream is not exist');
        continue;
      }
      await remove(peerMediaStream);
      logger.i(
          'A peerConnection remoteStream video stream ${stream.id} is removed');
    }
  }

  ///从会议的指定连接或者所有连接中移除local peerMediaStream，并且都重新协商
  removePeerMediaStream(List<PeerMediaStream> peerMediaStreams,
      {AdvancedPeerConnection? peerConnection}) async {
    if (peerConnection != null) {
      for (var peerMediaStream in peerMediaStreams) {
        await peerConnection.removeStream(peerMediaStream);
      }
      await peerConnection.negotiate();
    } else {
      for (AdvancedPeerConnection peerConnection in _peerConnections.values) {
        for (var peerMediaStream in peerMediaStreams) {
          await peerConnection.removeStream(peerMediaStream);
        }
        await peerConnection.negotiate();
      }
    }
  }

  ///从会议中移除指定连接
  ///把指定连接中的本地媒体关闭并且移除
  removeAdvancedPeerConnection(AdvancedPeerConnection peerConnection) async {
    var key = _getKey(peerConnection.peerId, peerConnection.clientId);
    var advancedPeerConnection = _peerConnections.remove(key);
    if (advancedPeerConnection != null) {
      peerConnection.unregisterWebrtcEvent(
          WebrtcEventType.track, _onAddRemoteTrack);
      peerConnection.unregisterWebrtcEvent(
          WebrtcEventType.removeTrack, _onRemoveRemoteTrack);
      peerConnection.unregisterWebrtcEvent(WebrtcEventType.closed, _onClosed);
      List<PeerMediaStream> peerMediaStreams =
          localPeerMediaStreamController.peerMediaStreams;
      if (peerMediaStreams.isNotEmpty) {
        await removePeerMediaStream(peerMediaStreams,
            peerConnection: peerConnection);
      }
      await _removePeerMediaStream(peerConnection);
    }
  }

  ///webrtc连接被关闭时，移除连接
  Future<void> _onClosed(WebrtcEvent webrtcEvent) async {
    AdvancedPeerConnection peerConnection = webrtcEvent.data;
    await removeAdvancedPeerConnection(peerConnection);
  }

  ///远程流到来渲染流，激活add事件
  Future<void> _onAddRemoteTrack(WebrtcEvent webrtcEvent) async {
    Map<String, dynamic> data = webrtcEvent.data;
    MediaStream? stream = data['stream'];
    MediaStreamTrack track = data['track'];
    String peerId = webrtcEvent.peerId;
    String clientId = webrtcEvent.clientId;
    String name = webrtcEvent.name;
    if (stream != null) {
      String streamId = stream.id;
      PeerMediaStream? peerMediaStream = await getPeerMediaStream(streamId);
      if (peerMediaStream != null) {
        peerMediaStream.setStream(stream);
        return;
      }
      peerMediaStream = PeerMediaStream();
      await peerMediaStream.buildMediaStream(stream, peerId,
          clientId: clientId, name: name);
      add(peerMediaStream);
    } else {
      logger.e('onAddRemoteTrack stream is null');
    }
  }

  ///远程关闭流事件触发，激活remove事件
  Future<void> _onRemoveRemoteTrack(WebrtcEvent webrtcEvent) async {
    Map<String, dynamic> data = webrtcEvent.data;
    MediaStream? stream = data['stream'];
    MediaStreamTrack track = data['track'];
    if (stream != null) {
      PeerMediaStream? peerMediaStream = await getPeerMediaStream(stream.id);
      if (peerMediaStream != null) {
        var mediaStream = peerMediaStream.mediaStream;
        if (mediaStream != null) {
          // List<MediaStreamTrack> tracks = mediaStream.getTracks();
          // List<MediaStreamTrack> removes = [];
          // for (MediaStreamTrack mediaStreamTrack in tracks) {
          //   if (mediaStreamTrack.id == track.id) {
          //     removes.add(mediaStreamTrack);
          //   }
          // }
          // for (MediaStreamTrack mediaStreamTrack in removes) {
          //   await mediaStream.removeTrack(mediaStreamTrack);
          // }
          // tracks = mediaStream.getTracks();
          // if (tracks.isEmpty) {
          //   await remove(peerMediaStream);
          //   await close(peerMediaStream);
          // }
          await close(peerMediaStream);
        }
      }
    } else {
      logger.e('onAddRemoteTrack stream is null');
    }
  }

  ///退出会议，移除所有的webrtc连接
  ///激活exit事件
  exit() async {
    //先移除，后关闭
    var peerMediaStreams = getPeerMediaStreams();
    for (var peerMediaStream in peerMediaStreams.values) {
      await peerMediaStream.close();
    }
    peerMediaStreams.clear();
    currentPeerMediaStream = null;
    mainPeerMediaStream = null;
    List<AdvancedPeerConnection> peerConnections = [..._peerConnections.values];
    for (var peerConnection in peerConnections) {
      await removeAdvancedPeerConnection(peerConnection);
    }
    _peerConnections.clear();
    conferenceChatMessageController.setChatMessage(null);
    conferenceChatMessageController.setChatSummary(null);
    await onPeerMediaStreamOperator(PeerMediaStreamOperator.exit.name, null);
  }
}

///所有的正在视频会议的池，包含多个视频会议，每个会议的会议号是视频通话邀请的消息号
class P2pConferenceClientPool with ChangeNotifier {
  final Map<String, P2pConferenceClient> _p2pConferenceClients = {};

  //当前会议编号
  String? _conferenceId;

  P2pConferenceClientPool();

  List<P2pConferenceClient> get p2pConferenceClients {
    return [..._p2pConferenceClients.values];
  }

  ///根据当前的视频邀请消息，查找或者创建当前消息对应的会议，并设置为当前会议
  Future<void> createConferenceChatMessageController(
      ChatSummary chatSummary, ChatMessage chatMessage) async {
    //创建基于当前聊天的视频消息控制器
    if (chatMessage.subMessageType == ChatMessageSubType.videoChat.name) {
      ConferenceChatMessageController? conferenceChatMessageController =
          getConferenceChatMessageController(chatMessage.messageId!);
      if (conferenceChatMessageController == null) {
        conferenceChatMessageController = ConferenceChatMessageController();
        await conferenceChatMessageController.setChatSummary(chatSummary);
        await conferenceChatMessageController.setChatMessage(chatMessage);
        createP2pConferenceClient(conferenceChatMessageController);
      } else {
        conferenceId = conferenceChatMessageController.conferenceId;
      }
    }
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

  ///创建新的远程视频会议控制器，假如会议号已经存在，直接返回控制器
  ///在发起者接收到至少一个同意回执，开始重新协商，或者接收者发送出同意回执的时候调用
  P2pConferenceClient createP2pConferenceClient(
      ConferenceChatMessageController conferenceChatMessageController) {
    String conferenceId = conferenceChatMessageController.conferenceId!;
    P2pConferenceClient? p2pConferenceClient =
        _p2pConferenceClients[conferenceId];
    if (p2pConferenceClient == null) {
      p2pConferenceClient = P2pConferenceClient(
          conferenceChatMessageController: conferenceChatMessageController);
      _p2pConferenceClients[conferenceId] = p2pConferenceClient;
    }
    this.conferenceId = conferenceId;

    return p2pConferenceClient;
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
  removePeerMediaStream(
      String conferenceId, List<PeerMediaStream> peerMediaStreams,
      {AdvancedPeerConnection? peerConnection}) async {
    P2pConferenceClient? p2pConferenceClient =
        _p2pConferenceClients[conferenceId];
    if (p2pConferenceClient != null) {
      await p2pConferenceClient.removePeerMediaStream(peerMediaStreams,
          peerConnection: peerConnection);
    }
  }

  ///根据会议编号退出会议
  ///调用对应会议的退出方法，然后从会议池中删除，设置当前会议编号为null
  exitConference(String conferenceId) async {
    P2pConferenceClient? p2pConferenceClient =
        _p2pConferenceClients[conferenceId];
    if (p2pConferenceClient != null) {
      await p2pConferenceClient.exit();
      _p2pConferenceClients.remove(conferenceId);
      if (conferenceId == _conferenceId) {
        _conferenceId = null;
      }
      notifyListeners();
    }
  }
}

///存放已经开始的会议，就是发起者接收到至少一个同意回执，开始重新协商，或者接收者发送出同意回执
final P2pConferenceClientPool p2pConferenceClientPool =
    P2pConferenceClientPool();
