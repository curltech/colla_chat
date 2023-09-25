import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';

///这是webrtc信号服务器的客户端实现，可以发送和接收信号服务器的数据
class SignalAction extends BaseAction {
  SignalAction(MsgType msgType) : super(msgType);

  ///发送webrtc信号
  Future<bool> signal(WebrtcSignal signal, String targetPeerId,
      {String? targetClientId}) async {
    ChainMessage? chainMessage = await signalAction.prepareSend(signal,
        targetPeerId: targetPeerId, targetClientId: targetClientId);
    // TODO: 视频通话的signal加密送过去解密完数据有问题，具体原因还没找到
    chainMessage.needEncrypt = false;
    chainMessage.needCompress = false;

    return await signalAction.send(chainMessage);
  }

  @override
  Future<void> response(ChainMessage chainMessage) async {}

  @override
  Future<void> transferPayload(ChainMessage chainMessage) async {
    super.transferPayload(chainMessage);
    var json = chainMessage.payload;
    WebrtcSignal signal = WebrtcSignal.fromJson(json);
    chainMessage.payload = signal;
  }
}

final signalAction = SignalAction(MsgType.SIGNAL);
