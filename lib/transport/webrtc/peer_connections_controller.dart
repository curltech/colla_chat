import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/local_video_render_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter/material.dart';

///一组webrtc连接，这些连接与自己正在视频通话，此控制器用于通知视频通话界面的刷新
class PeerConnectionsController with ChangeNotifier {
  ///对方的队列，每一个peerId的元素是一个列表，具有相同的peerId和不同的clientId
  final Map<String, Map<String, AdvancedPeerConnection>> _peerConnections = {};
  String? _roomId;

  //key为连接id
  Map<String, VideoRenderController> videoRenderControllers = {};

  VideoRenderController buildVideoRenderController() {
    List<PeerVideoRender> renders = [];
    for (var videoRenderController in videoRenderControllers.values) {
      renders.addAll(videoRenderController.videoRenders.values);
    }
    return VideoRenderController(videoRenders: renders);
  }

  ///获取连接
  List<AdvancedPeerConnection> get(String peerId, {String? clientId}) {
    List<AdvancedPeerConnection> advancedPeerConnections = [];
    if (_peerConnections.containsKey(peerId)) {
      Map<String, AdvancedPeerConnection>? pcs = _peerConnections[peerId];
      if (pcs != null) {
        if (clientId != null) {
          AdvancedPeerConnection? advancedPeerConnection = pcs[clientId];
          if (advancedPeerConnection != null) {
            advancedPeerConnections.add(advancedPeerConnection);
          }
        } else {
          advancedPeerConnections.addAll(pcs.values);
        }
      }
    }
    return advancedPeerConnections;
  }

  ///连接的流发送变化
  update(String peerId, {required String clientId}) {
    var pcs = _peerConnections[peerId];
    if (pcs != null) {
      if (pcs.containsKey(clientId)) {
        //var videoRenders = remoteVideoRenderController.videoRenders;
        notifyListeners();
      }
    }
  }

  ///将连接加入控制器，此连接将与自己展开视频通话
  add(String peerId, {required String clientId}) {
    AdvancedPeerConnection? peerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (peerConnection != null) {
      var pcs = _peerConnections[peerId];
      if (pcs == null) {
        pcs = {};
        _peerConnections[peerId] = pcs;
      }
      pcs[clientId] = peerConnection;
      _addPeerConnection(peerConnection);
      logger.i(
          'AdvancedPeerConnection peerId:peerId clientId:$clientId added in PeerConnectionsController');
    }
  }

  ///将连接移出控制器，视频通话关闭
  remove(String peerId, {String? clientId}) {
    var pcs = _peerConnections[peerId];
    if (pcs != null) {
      if (clientId != null) {
        AdvancedPeerConnection? advancedPeerConnection = pcs.remove(clientId);
        if (advancedPeerConnection != null) {
          _removePeerConnection(advancedPeerConnection);
        }
      } else {
        for (var pc in pcs.values) {
          _removePeerConnection(pc);
        }
        pcs.clear();
      }
      if (pcs.isEmpty) {
        _peerConnections.remove(peerId);
      }
    }
    notifyListeners();
  }

  ///清除所有连接
  clear() {
    for (var pcs in _peerConnections.values) {
      for (var pc in pcs.values) {
        _removePeerConnection(pc);
      }
    }
    _peerConnections.clear();
  }

  void _addPeerConnection(AdvancedPeerConnection advancedPeerConnection) {
    VideoRenderController? videoRenderController =
        videoRenderControllers[advancedPeerConnection.basePeerConnection.id];
    if (videoRenderController == null) {
      videoRenderController = VideoRenderController();
      videoRenderControllers[advancedPeerConnection.basePeerConnection.id] =
          videoRenderController;
    }
  }

  void _removePeerConnection(AdvancedPeerConnection advancedPeerConnection) {
    videoRenderControllers.remove(advancedPeerConnection.basePeerConnection.id);
  }
}

final PeerConnectionsController peerConnectionsController =
    PeerConnectionsController();
