import 'package:colla_chat/entity/chat/chat.dart';

import '../../../entity/p2p/message.dart';
import '../../../tool/util.dart';
import '../baseaction.dart';

/// 在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
class P2pChatAction extends BaseAction {
  P2pChatAction(MsgType msgType) : super(msgType);

  Future<dynamic> chat(dynamic data, String targetPeerId) async {
    ChainMessage? chainMessage =
        await prepareSend(data, targetPeerId: targetPeerId);
    // 已经使用signal protocol加密，不用再加密
    //chainMessage.NeedEncrypt = true
    //chainMessage.NeedSlice = true
    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response;
    }

    return null;
  }

  @override
  Future<void> transferPayload(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.dataBlock.name) {
      ChatMessage chatMessage;
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
