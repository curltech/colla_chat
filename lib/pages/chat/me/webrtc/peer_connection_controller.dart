import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:flutter/material.dart';


///webrtc连接池控制器，用于跟踪连接的状态变化
class PeerConnectionPoolController with ChangeNotifier {
  //新连接被创建
  onCreated(WebrtcEvent event) async {
    //notifyListeners();
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

  void onStatus(WebrtcEvent event) async {
    notifyListeners();
  }
}

final PeerConnectionPoolController peerConnectionPoolController =
    PeerConnectionPoolController();
