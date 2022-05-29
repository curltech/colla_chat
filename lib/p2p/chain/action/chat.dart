import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

// Socket消息类型
enum ChatMessageType {
  LOGOUT,
  MIGRATE,
  BACKUP,
  RESTORE,
}

/**
    在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 */
class ChatAction extends BaseAction {
  ChatAction(MsgType msgType) : super(msgType);

  Future<dynamic> chat(
      String connectPeerId, dynamic data, String targetPeerId) async {
    ChainMessage chainMessage =
        await prepareSend(connectPeerId, data, targetPeerId: targetPeerId);
    chainMessage.needEncrypt = true;

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

  @override
  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    ChainMessage? _chainMessage = await super.receive(chainMessage);
    if (_chainMessage != null && receivers.isNotEmpty) {
      receivers.forEach((String key, dynamic receiver) async =>
          {await receiver(_chainMessage.payload)});

      return null;
    }

    return null;
  }
}

final chatAction = ChatAction(MsgType.CHAT);
