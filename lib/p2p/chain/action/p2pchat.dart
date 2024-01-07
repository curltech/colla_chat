import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/action/chat.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

///服务进行消息推送
class P2pChatAction extends ChatAction {
  P2pChatAction(super.msgType);

  @override
  Future<void> transferPayload(ChainMessage chainMessage) async {
    super.transferPayload(chainMessage);
    if (chainMessage.payloadType == PayloadType.dataBlock.name) {
      Map payload = {};
      var jsons = chainMessage.payload;
      if (jsons is List) {
        for (var json in jsons) {
          payload = json['payload'];
        }
      }
      chainMessage.payload = payload;
    }
  }
}

final p2pChatAction = P2pChatAction(MsgType.P2PCHAT);
