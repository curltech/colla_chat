import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

///根据目标peerclient的peerid，电话和名称搜索，异步返回
class FindClientAction extends BaseAction {
  FindClientAction(MsgType msgType) : super(msgType);

  Future<List<dynamic>?> findClient(
      String targetPeerId, String mobileNumber, String name) async {
    ChainMessage chainMessage = await prepareSend(
        {'peerId': targetPeerId, 'mobileNumber': mobileNumber, 'name': name});

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

  @override
  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    ChainMessage? chainMessage_ = await super.receive(chainMessage);
    if (chainMessage_ != null && receivers.isNotEmpty) {
      receivers.forEach((String key, dynamic receiver) async =>
          {await receiver(chainMessage_.payload)});

      return null;
    }

    return null;
  }
}

final findClientAction = FindClientAction(MsgType.FINDCLIENT);
