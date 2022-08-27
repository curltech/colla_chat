import 'package:colla_chat/transport/webrtc/peer_connection_pool.dart';
import 'package:flutter/material.dart';

import '../../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../../transport/webrtc/peer_video_render.dart';

///一组webrtc连接，这些连接与自己正在视频通话，此控制器用于通知视频通话界面的刷新
class PeerConnectionsController with ChangeNotifier {
  ///对方的队列，每一个peerId的元素是一个列表，具有相同的peerId和不同的clientId
  final Map<String, Map<String, AdvancedPeerConnection>> _peerConnections = {};
  String? _roomId;

  update(String peerId, {String? clientId}) {
    AdvancedPeerConnection? peerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (peerConnection != null) {
      clientId = clientId ?? '';
      var pcs = _peerConnections[peerId];
      if (pcs != null) {
        if (pcs.containsKey(clientId)) {
          notifyListeners();
        }
      }
    }
  }

  add(String peerId, {String? clientId}) {
    AdvancedPeerConnection? peerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (peerConnection != null) {
      clientId = clientId ?? '';
      var pcs = _peerConnections[peerId];
      if (pcs == null) {
        pcs = {};
        _peerConnections[peerId] = pcs;
      }
      pcs[clientId] = peerConnection;
      notifyListeners();
    }
  }

  remove(String peerId, {String? clientId}) {
    var pcs = _peerConnections[peerId];
    if (pcs != null) {
      if (clientId != null) {
        pcs.remove(clientId);
      } else {
        pcs.clear();
      }
      if (pcs.isEmpty) {
        _peerConnections.remove(peerId);
      }
    }
    notifyListeners();
  }

  clear() {
    _peerConnections.clear();
  }

  Map<String, PeerVideoRender> videoRenders(
      {String? peerId, String? clientId}) {
    Map<String, PeerVideoRender> allVideoRenders = {};
    //allVideoRenders.addAll(localMediaController.videoRenders);
    List<AdvancedPeerConnection> peerConnections = [];
    if (peerId != null) {
      var pcs = _peerConnections[peerId];
      if (pcs != null) {
        if (clientId != null) {
          AdvancedPeerConnection? advancedPeerConnection = pcs[clientId];
          if (advancedPeerConnection != null) {
            peerConnections.add(advancedPeerConnection);
          }
        } else {
          peerConnections.addAll(pcs.values);
        }
      }
    } else {
      for (var pcs in _peerConnections.values) {
        peerConnections.addAll(pcs.values);
      }
    }
    for (var peerConnection in peerConnections) {
      for (var entry in peerConnection.videoRenders.entries) {
        String id = entry.key;
        var render = entry.value;
        if (!allVideoRenders.containsKey(id)) {
          allVideoRenders[id] = render;
        }
      }
    }

    return allVideoRenders;
  }
}

final PeerConnectionsController peerConnectionsController =
    PeerConnectionsController();
