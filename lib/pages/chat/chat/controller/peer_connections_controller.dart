import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter/material.dart';

///一组webrtc连接，这些连接与自己正在视频通话，此控制器用于通知视频通话界面的刷新
class PeerConnectionsController with ChangeNotifier {
  ///对方的队列，每一个peerId的元素是一个列表，具有相同的peerId和不同的clientId
  final Map<String, Map<String, AdvancedPeerConnection>> _peerConnections = {};
  String? _roomId;

  VideoRenderController localVideoRenderController = VideoRenderController();

  VideoRenderController remoteVideoRenderController = VideoRenderController();

  AdvancedPeerConnection get() {
    return _peerConnections.values.first.values.first;
  }

  modify(String peerId, {required String clientId}) {
    AdvancedPeerConnection? peerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (peerConnection != null) {
      var pcs = _peerConnections[peerId];
      if (pcs != null) {
        if (pcs.containsKey(clientId)) {
          notifyListeners();
        }
      }
    }
  }

  //将连接加入控制器，此连接将与自己展开视频通话
  addPeerConnection(String peerId, {required String clientId}) {
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

  //将连接移出控制器，视频通话关闭
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

  clear() {
    for (var pcs in _peerConnections.values) {
      for (var pc in pcs.values) {
        _removePeerConnection(pc);
      }
    }
    _peerConnections.clear();
  }

  void _addPeerConnection(AdvancedPeerConnection advancedPeerConnection) {
    for (var entry in advancedPeerConnection.localVideoRenders.entries) {
      String id = entry.key;
      var render = entry.value;
      var videoRenders = localVideoRenderController.videoRenders;
      if (!videoRenders.containsKey(id)) {
        localVideoRenderController.put(render);
      }
    }
    for (var entry in advancedPeerConnection.remoteVideoRenders.entries) {
      String id = entry.key;
      var render = entry.value;
      var videoRenders = remoteVideoRenderController.videoRenders;
      if (!videoRenders.containsKey(id)) {
        remoteVideoRenderController.put(render);
      }
    }
  }

  void _removePeerConnection(AdvancedPeerConnection advancedPeerConnection) {
    for (var entry in advancedPeerConnection.localVideoRenders.entries) {
      String id = entry.key;
      var videoRenders = localVideoRenderController.videoRenders;
      if (!videoRenders.containsKey(id)) {
        localVideoRenderController.close(id: id);
      }
    }
    for (var entry in advancedPeerConnection.remoteVideoRenders.entries) {
      String id = entry.key;
      var render = entry.value;
      var videoRenders = remoteVideoRenderController.videoRenders;
      if (!videoRenders.containsKey(id)) {
        remoteVideoRenderController.close(id: id);
      }
    }
  }
}

final PeerConnectionsController peerConnectionsController =
    PeerConnectionsController();
