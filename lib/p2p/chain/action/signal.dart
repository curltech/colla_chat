import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';

import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

///这是webrtc信号服务器的客户端实现，可以发送和接收信号服务器的数据
class SignalAction extends BaseAction {
  SignalAction(MsgType msgType) : super(msgType);

  ///发送webrtc信号
  Future<dynamic> signal(WebrtcSignal signal, String targetPeerId) async {
    ChainMessage? chainMessage =
        await signalAction.prepareSend(signal, targetPeerId: targetPeerId);
    // TODO: 视频通话的signal加密送过去解密完数据有问题，具体原因还没找到
    chainMessage.needEncrypt = false;
    chainMessage.needCompress = false;

    ChainMessage? response = await signalAction.send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }
}

final signalAction = SignalAction(MsgType.SIGNAL);
