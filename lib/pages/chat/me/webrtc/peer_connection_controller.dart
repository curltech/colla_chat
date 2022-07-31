import 'package:flutter/material.dart';

import '../../../../entity/p2p/message.dart';
import '../../../../p2p/chain/action/signal.dart';
import '../../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../../transport/webrtc/peer_connection_pool.dart';

///webrtc连接池控制器
class PeerConnectionPoolController with ChangeNotifier {
  //新连接被创建
  onCreated(WebrtcEvent event) async {
    notifyListeners();
  }

  //新消息到来
  onMessage(WebrtcEvent event) async {
    notifyListeners();
  }

  //新连接被建立
  onConnected(WebrtcEvent event) async {
    notifyListeners();
  }

  //连接被关闭
  onClosed(WebrtcEvent event) async {
    notifyListeners();
  }

  //连接错误
  onError(WebrtcEvent event) async {
    notifyListeners();
  }

  //新流到来
  onStream(WebrtcEvent event) async {
    notifyListeners();
  }

  //新轨道到来
  onTrack(WebrtcEvent event) async {
    notifyListeners();
  }
}

final PeerConnectionPoolController peerConnectionPoolController =
    PeerConnectionPoolController();
