import 'package:flutter/material.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../transport/webrtc/advanced_peer_connection.dart';

///webrtc连接池控制器
class PeerConnectionPoolController with ChangeNotifier {
  //新连接被创建
  onCreated(WebrtcEvent event) async {
    //notifyListeners();
  }

  //新消息到来
  onMessage(ChatMessage chatMessage) async {
    ///回执消息
    if (chatMessage.subMessageType == ChatSubMessageType.chatReceipt.name) {}
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
  onAddStream(WebrtcEvent event) async {
    notifyListeners();
  }

  onRemoveStream(WebrtcEvent event) async {
    notifyListeners();
  }

  //新轨道到来
  onTrack(WebrtcEvent event) async {
    notifyListeners();
  }

  onAddTrack(WebrtcEvent event) async {
    notifyListeners();
  }

  onRemoveTrack(WebrtcEvent event) async {
    notifyListeners();
  }

  void onStatus(WebrtcEvent event) async {
    notifyListeners();
  }
}

final PeerConnectionPoolController peerConnectionPoolController =
    PeerConnectionPoolController();
