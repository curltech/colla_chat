import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/action/chat.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/tool/json_util.dart';

///服务进行消息推送
class P2pChatAction extends ChatAction {
  P2pChatAction(MsgType msgType) : super(msgType);

  @override
  Future<void> transferPayload(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.dataBlock.name) {
      var payload = chainMessage.payload;
      var jsons = JsonUtil.toJson(payload);
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
