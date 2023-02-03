import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

///普通发送和接受消息的Action，服务器端支持根据目标peerId进行转发
class ChatAction extends BaseAction {
  ChatAction(MsgType msgType) : super(msgType);

  Future<dynamic> chat(dynamic data, String targetPeerId) async {
    ChainMessage chainMessage =
        await prepareSend(data, targetPeerId: targetPeerId);
    //chainMessage.NeedEncrypt = true
    //chainMessage.NeedSlice = true
    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }
}

final chatAction = ChatAction(MsgType.CHAT);
