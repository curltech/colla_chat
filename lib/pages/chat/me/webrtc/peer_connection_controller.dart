import 'package:flutter/material.dart';

import '../../../../entity/p2p/message.dart';
import '../../../../p2p/chain/action/signal.dart';
import '../../../../transport/webrtc/peer_connection_pool.dart';

///webrtc连接池控制器
class PeerConnectionPoolController with ChangeNotifier {
  final PeerConnectionPool _peerConnectionPool = peerConnectionPool;

  PeerConnectionPoolController() {
    signalAction.registerReceiver(receive);
  }

  ///接收信号消息
  receive(ChainMessage chainMessage) async {
    _peerConnectionPool.receive(chainMessage);
    notifyListeners();
  }
}

final PeerConnectionPoolController peerConnectionPoolController =
    PeerConnectionPoolController();
