import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

///视频通话的一个房间内的所有的webrtc连接及其包含的远程视频，
///这些连接与自己正在视频通话，此控制器用于通知视频通话界面的刷新
class RemoteVideoRenderController extends VideoRenderController {
  final Key key = UniqueKey();

  ///根据peerId和clientId对应的所有的webrtc连接
  final Map<String, AdvancedPeerConnection> _peerConnections = {};
  final VideoChatMessageController? videoChatMessageController;

  ///根据peerId和clientId的连接所对应的视频render控制器，每一个视频render控制器包含多个视频render
  Map<String, VideoRenderController> videoRenderControllers = {};

  RemoteVideoRenderController({this.videoChatMessageController});

  String _getKey(String peerId, String clientId) {
    var key = '$peerId:$clientId';
    return key;
  }

  ///增加远程视频render，确保之前连接已经加入
  ///新增的远程视频render还要加入到对应的连接的控制器中
  @override
  add(PeerVideoRender videoRender) {
    super.add(videoRender);
    AdvancedPeerConnection? peerConnection =
        getAdvancedPeerConnection(videoRender.peerId!, videoRender.clientId!);
    if (peerConnection != null) {
      var key = _getKey(peerConnection.peerId, peerConnection.clientId);
      VideoRenderController? videoRenderController =
          videoRenderControllers[key];
      if (videoRenderController == null) {
        videoRenderController = VideoRenderController();
        videoRenderControllers[key] = videoRenderController;
      }
      videoRenderController.add(videoRender);
    }
  }

  ///把本地新的videoRender加入到指定连接或者会议的所有连接中，并且都重新协商
  ///指定连接用在加入新的连接的时候，所有连接用在加入新的videoRender的时候
  addLocalVideoRender(List<PeerVideoRender> videoRenders,
      {AdvancedPeerConnection? peerConnection}) async {
    if (peerConnection != null) {
      for (var videoRender in videoRenders) {
        await peerConnection.addLocalRender(videoRender);
      }
      await peerConnection.negotiate();
    } else {
      for (AdvancedPeerConnection peerConnection in _peerConnections.values) {
        for (var videoRender in videoRenders) {
          await peerConnection.addLocalRender(videoRender);
        }
        await peerConnection.negotiate();
      }
    }
  }

  ///会议的指定连接或者所有连接中移除本地videoRender，并且都重新协商
  removeLocalVideoRender(List<PeerVideoRender> videoRenders,
      {AdvancedPeerConnection? peerConnection}) async {
    if (peerConnection != null) {
      for (var videoRender in videoRenders) {
        await peerConnection.removeLocalRender(videoRender);
      }
      await peerConnection.negotiate();
    } else {
      for (AdvancedPeerConnection peerConnection in _peerConnections.values) {
        for (var videoRender in videoRenders) {
          await peerConnection.removeLocalRender(videoRender);
        }
        await peerConnection.negotiate();
      }
    }
  }

  ///关闭streamId的流或者关闭附件所有控制器的所有流，相当于关闭了会议
  @override
  close({String? streamId}) {
    super.close(streamId: streamId);
    if (streamId == null) {
      List<String> keys = videoRenderControllers.keys.toList();
      for (var key in keys) {
        var advancedPeerConnection = _peerConnections[key];
        if (advancedPeerConnection != null) {
          removeAdvancedPeerConnection(advancedPeerConnection);
        }
      }
    } else {
      List<String> keys = videoRenderControllers.keys.toList();
      for (var key in keys) {
        var videoRenderController = videoRenderControllers[key];
        if (videoRenderController != null) {
          videoRenderController.close(streamId: streamId);
          if (videoRenderController.videoRenders.isEmpty) {
            _peerConnections.remove(key);
            videoRenderControllers.remove(key);
          }
        }
      }
    }
  }

  ///清除peerId和clientId对应的连接和相应的render
  ///或者关闭所有的控制器的所有流，相对于关闭房间
  clear({String? peerId, String? clientId}) {
    if (peerId == null && clientId == null) {
      close();
    } else {
      var key = _getKey(peerId!, clientId!);
      var advancedPeerConnection = _peerConnections[key];
      if (advancedPeerConnection != null) {
        removeAdvancedPeerConnection(advancedPeerConnection);
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

  ///将连接加入控制器，此连接将与自己展开视频通话
  addAdvancedPeerConnection(AdvancedPeerConnection peerConnection) {
    var key = _getKey(peerConnection.peerId, peerConnection.clientId);
    if (!_peerConnections.containsKey(key)) {
      _peerConnections[key] = peerConnection;
      peerConnection.registerWebrtcEvent(
          WebrtcEventType.stream, _onAddRemoteStream);
      peerConnection.registerWebrtcEvent(
          WebrtcEventType.removeStream, _onRemoveRemoteStream);
      VideoRenderController? videoRenderController =
          videoRenderControllers[key];
      if (videoRenderController == null) {
        videoRenderController = VideoRenderController();
        videoRenderControllers[key] = videoRenderController;
      }
    }
  }

  ///远程流到来渲染流
  Future<void> _onAddRemoteStream(WebrtcEvent webrtcEvent) async {
    MediaStream stream = webrtcEvent.data;
    String peerId = webrtcEvent.peerId;
    String clientId = webrtcEvent.clientId;
    String name = webrtcEvent.name;
    String streamId = stream.id;
    PeerVideoRender? videoRender = videoRenders[streamId];
    if (videoRender != null) {
      return;
    }
    PeerVideoRender render = await PeerVideoRender.fromMediaStream(peerId,
        clientId: clientId, name: name, stream: stream);
    add(render);
  }

  //远程关闭流事件触发
  Future<void> _onRemoveRemoteStream(WebrtcEvent webrtcEvent) async {
    MediaStream stream = webrtcEvent.data;
    String streamId = stream.id;
    close(streamId: streamId);
  }

  ///将连接移出控制器，对应的视频通话流关闭
  removeAdvancedPeerConnection(AdvancedPeerConnection peerConnection) {
    var key = _getKey(peerConnection.peerId, peerConnection.clientId);
    var advancedPeerConnection = _peerConnections.remove(key);
    if (advancedPeerConnection != null) {
      peerConnection.unregisterWebrtcEvent(
          WebrtcEventType.stream, _onAddRemoteStream);
      peerConnection.unregisterWebrtcEvent(
          WebrtcEventType.removeStream, _onRemoveRemoteStream);
      VideoRenderController? controller = videoRenderControllers.remove(key);
      if (controller != null) {
        for (var streamId in controller.videoRenders.keys) {
          close(streamId: streamId);
        }
        controller.close();
      }
      notifyListeners();
    }
  }
}

///所有的视频通话的房间的池，包含多个会议，每个会议的会议号是视频通话邀请的消息号
class VideoConferenceRenderPool with ChangeNotifier {
  Map<String, RemoteVideoRenderController> remoteVideoRenderControllers = {};
  String? _conferenceId;

  VideoConferenceRenderPool();

  ///获取当前会议号
  String? get conferenceId {
    return _conferenceId;
  }

  ///设置当前会议号
  set conferenceId(String? conferenceId) {
    if (_conferenceId != conferenceId) {
      if (conferenceId != null) {
        if (remoteVideoRenderControllers.containsKey(conferenceId)) {
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

  ///获取当前房间的控制器
  RemoteVideoRenderController? get remoteVideoRenderController {
    if (_conferenceId != null) {
      return remoteVideoRenderControllers[_conferenceId];
    }
    return null;
  }

  ///获取当前会议控制器
  VideoChatMessageController? get videoChatMessageController {
    if (_conferenceId != null) {
      return remoteVideoRenderControllers[_conferenceId]
          ?.videoChatMessageController;
    }
    return null;
  }

  ///根据会议号返回会议控制器，没有则返回null
  RemoteVideoRenderController? getRemoteVideoRenderController(
      String conferenceId) {
    return remoteVideoRenderControllers[conferenceId];
  }

  VideoChatMessageController? getVideoChatMessageController(
      String conferenceId) {
    return getRemoteVideoRenderController(conferenceId)
        ?.videoChatMessageController;
  }

  Conference? getConference(String conferenceId) {
    return getRemoteVideoRenderController(conferenceId)
        ?.videoChatMessageController
        ?.conference;
  }

  ///创建新的远程视频会议控制器，假如会议号已经存在，直接返回控制器
  ///在发起者接收到至少一个同意回执，开始重新协商，或者接收者发送出同意回执的时候调用
  RemoteVideoRenderController createRemoteVideoRenderController(
      VideoChatMessageController videoChatMessageController) {
    String conferenceId = videoChatMessageController.conferenceId!;
    RemoteVideoRenderController? remoteVideoRenderController =
        remoteVideoRenderControllers[conferenceId];
    if (remoteVideoRenderController == null) {
      remoteVideoRenderController = RemoteVideoRenderController(
          videoChatMessageController: videoChatMessageController);
      remoteVideoRenderControllers[conferenceId] = remoteVideoRenderController;
    }
    _conferenceId = conferenceId;

    return remoteVideoRenderController;
  }

  ///把本地新的videoRender加入到会议的所有连接中，并且都重新协商
  addLocalVideoRender(String conferenceId, List<PeerVideoRender> videoRenders,
      {AdvancedPeerConnection? peerConnection}) async {
    RemoteVideoRenderController? remoteVideoRenderController =
        remoteVideoRenderControllers[conferenceId];
    if (remoteVideoRenderController != null) {
      await remoteVideoRenderController.addLocalVideoRender(videoRenders,
          peerConnection: peerConnection);
    }
  }

  removeLocalVideoRender(
      String conferenceId, List<PeerVideoRender> videoRenders,
      {AdvancedPeerConnection? peerConnection}) async {
    RemoteVideoRenderController? remoteVideoRenderController =
        remoteVideoRenderControllers[conferenceId];
    if (remoteVideoRenderController != null) {
      await remoteVideoRenderController.removeLocalVideoRender(videoRenders,
          peerConnection: peerConnection);
    }
  }

  closeConferenceId(String conferenceId) {
    RemoteVideoRenderController? remoteVideoRenderController =
        remoteVideoRenderControllers[conferenceId];
    if (remoteVideoRenderController != null) {
      remoteVideoRenderController.close();
    }
    if (conferenceId == _conferenceId) {
      _conferenceId = null;
    }
  }
}

///存放已经开始的会议，就是发起者接收到至少一个同意回执，开始重新协商，或者接收者发送出同意回执
final VideoConferenceRenderPool videoConferenceRenderPool =
    VideoConferenceRenderPool();
