import 'package:colla_chat/transport/webrtc/webrtc_core_peer.dart';

import '../../../entity/p2p/message.dart';
import '../../../transport/webrtc/webrtcpeerpool.dart';
import '../baseaction.dart';

///这是webrtc信号服务器的客户端实现，可以发送和接收信号服务器的数据
class SignalAction extends BaseAction {
  SignalAction(MsgType msgType) : super(msgType) {
    webrtcPeerPool.registerSignalAction(this);
  }

  ///发送webrtc信号
  Future<dynamic> signal(WebrtcSignal signal, String targetPeerId) async {
    ChainMessage? chainMessage =
        await signalAction.prepareSend(signal, targetPeerId: targetPeerId);
    // TODO: 视频通话的signal加密送过去解密完数据有问题，具体原因还没找到
    //chainMessage.NeedEncrypt = true

    ChainMessage? response = await signalAction.send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

  @override
  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    ChainMessage? _chainMessage = await super.receive(chainMessage);
    if (_chainMessage != null && receivers.isNotEmpty) {
      signalAction.receivers.forEach((String key, dynamic receiver) {
        WebrtcSignal signal = WebrtcSignal.fromJson(_chainMessage.payload);
        receiver(_chainMessage.srcPeerId, _chainMessage.srcConnectPeerId,
            _chainMessage.srcConnectSessionId, signal);
      });

      return null;
    }
    return null;
  }
}

final signalAction = SignalAction(MsgType.SIGNAL);
