import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

///普通发送和接受消息的Action，服务器端支持根据目标peerId进行转发
///与P2pChat不同的地方是不进行消息推送
class ChatAction extends BaseAction {
  ChatAction(MsgType msgType) : super(msgType);

  Future<dynamic> chat(dynamic data, String targetPeerId) async {
    ChainMessage chainMessage =
        await prepareSend(data, targetPeerId: targetPeerId);
    //chainMessage.needEncrypt = true;

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }
}

final chatAction = ChatAction(MsgType.CHAT);
