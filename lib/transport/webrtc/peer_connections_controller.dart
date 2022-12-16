import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter/material.dart';

///一组webrtc连接，这些连接与自己正在视频通话，此控制器用于通知视频通话界面的刷新
class PeerConnectionsController extends VideoRenderController {
  ///对方的队列，每一个peerId的元素是一个列表，具有相同的peerId和不同的clientId
  final Map<String, AdvancedPeerConnection> _peerConnections = {};
  String? _roomId;

  //远程流的渲染器控制器，key为连接id
  Map<String, VideoRenderController> videoRenderControllers = {};

  @override
  add(PeerVideoRender videoRender) {
    super.add(videoRender);
    AdvancedPeerConnection? peerConnection =
        getAdvancedPeerConnection(videoRender.peerId!, videoRender.clientId!);
    if (peerConnection != null) {
      var key = '${peerConnection.peerId}:${peerConnection.clientId}';
      VideoRenderController? videoRenderController =
          videoRenderControllers[key];
      if (videoRenderController == null) {
        videoRenderController = VideoRenderController();
        videoRenderControllers[key] = videoRenderController;
      }
      videoRenderController.add(videoRender);
    }
  }

  @override
  close({String? streamId}) {
    super.close(streamId: streamId);
    if (streamId == null) {
      videoRenderControllers.clear();
    } else {
      List<String> ids = [];
      for (var entry in videoRenderControllers.entries) {
        VideoRenderController videoRenderController = entry.value;
        String id = entry.key;
        videoRenderController.close(streamId: streamId);
        if (videoRenderController.videoRenders.isEmpty) {
          ids.add(id);
        }
      }
      for (var id in ids) {
        videoRenderControllers.remove(id);
        _peerConnections.remove(id);
      }
    }
  }

  ///获取连接
  AdvancedPeerConnection? getAdvancedPeerConnection(
      String peerId, String clientId) {
    return _peerConnections['$peerId:$clientId'];
  }

  ///连接的流发送变化
  updateAdvancedPeerConnection(String peerId, String clientId) {
    var pc = _peerConnections['$peerId:$clientId'];
    if (pc != null) {
      //var videoRenders = remoteVideoRenderController.videoRenders;
      notifyListeners();
    }
  }

  ///将连接加入控制器，此连接将与自己展开视频通话
  addAdvancedPeerConnection(AdvancedPeerConnection peerConnection) {
    var key = '${peerConnection.peerId}:${peerConnection.clientId}';
    if (!_peerConnections.containsKey(key)) {
      _peerConnections[key] = peerConnection;
      _addPeerConnection(peerConnection);
      logger.i(
          'AdvancedPeerConnection peerId:peerId clientId:${peerConnection.clientId} added in PeerConnectionsController');
    }
  }

  ///将连接移出控制器，视频通话关闭
  removeAdvancedPeerConnection(AdvancedPeerConnection peerConnection) {
    var key = '${peerConnection.peerId}:${peerConnection.clientId}';
    var advancedPeerConnection = _peerConnections.remove(key);
    if (advancedPeerConnection != null) {
      _removePeerConnection(advancedPeerConnection);
    }
    notifyListeners();
  }

  ///清除所有连接
  clear() {
    for (var pc in _peerConnections.values) {
      _removePeerConnection(pc);
    }
    _peerConnections.clear();
  }

  void _addPeerConnection(AdvancedPeerConnection peerConnection) {
    var key = '${peerConnection.peerId}:${peerConnection.clientId}';
    VideoRenderController? videoRenderController = videoRenderControllers[key];
    if (videoRenderController == null) {
      videoRenderController = VideoRenderController();
      videoRenderControllers[key] = videoRenderController;
    }
  }

  void _removePeerConnection(AdvancedPeerConnection peerConnection) {
    var key = '${peerConnection.peerId}:${peerConnection.clientId}';
    videoRenderControllers.remove(key);
  }
}

final PeerConnectionsController peerConnectionsController =
    PeerConnectionsController();
