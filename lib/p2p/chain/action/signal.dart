import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';

import '../../../entity/p2p/chain_message.dart';
import '../baseaction.dart';

///这是webrtc信号服务器的客户端实现，可以发送和接收信号服务器的数据
class SignalAction extends BaseAction {
  SignalAction(MsgType msgType) : super(msgType);

  ///发送webrtc信号
  Future<dynamic> signal(WebrtcSignal signal, String targetPeerId,
      {String? targetClientId}) async {
    ChainMessage? chainMessage = await signalAction.prepareSend(signal,
        targetPeerId: targetPeerId, targetClientId: targetClientId);
    // TODO: 视频通话的signal加密送过去解密完数据有问题，具体原因还没找到
    chainMessage.needEncrypt = false;
    chainMessage.needCompress = false;

    ChainMessage? response = await signalAction.send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

  @override
  Future<void> transferPayload(ChainMessage chainMessage) async {
    var payload = chainMessage.payload;
    var json = JsonUtil.toJson(payload);
    WebrtcSignal signal = WebrtcSignal.fromJson(json);
    chainMessage.payload = signal;
  }
}

final signalAction = SignalAction(MsgType.SIGNAL);
