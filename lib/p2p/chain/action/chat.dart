import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

///普通发送和接受消息的Action，服务器端支持根据目标peerId进行转发
class ChatAction extends BaseAction {
  ChatAction(super.msgType);

  Future<bool> chat(dynamic data, String targetPeerId,
      {PayloadType? payloadType, bool needEncrypt = true}) async {
    ChainMessage chainMessage = await prepareSend(data,
        targetPeerId: targetPeerId, payloadType: payloadType);
    chainMessage.needEncrypt = needEncrypt;
    chainMessage.needSlice = true;

    return await send(chainMessage);
  }
}

final chatAction = ChatAction(MsgType.CHAT);
