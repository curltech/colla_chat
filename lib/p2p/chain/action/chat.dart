import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

///普通发送和接受消息的Action，服务器端支持根据目标peerId进行转发
class ChatAction extends BaseAction {
  ChatAction(MsgType msgType) : super(msgType);

  Future<bool> chat(dynamic data, String targetPeerId,
      {String? payloadType}) async {
    ChainMessage chainMessage =
        await prepareSend(data, targetPeerId: targetPeerId);
    chainMessage.needEncrypt = true;
    chainMessage.needSlice = true;
    if (payloadType != null) {
      chainMessage.payloadType = payloadType;
    }
    return await send(chainMessage);
  }
}

final chatAction = ChatAction(MsgType.CHAT);
