import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

///根据目标peerclient的peerid，电话和名称搜索，异步返回
class FindClientAction extends BaseAction {
  FindClientAction(MsgType msgType) : super(msgType);

  Future<List<dynamic>?> findClient(String targetPeerId, String mobileNumber,
      String email, String name) async {
    ChainMessage chainMessage = await prepareSend({
      'peerId': targetPeerId,
      'mobileNumber': mobileNumber,
      'email': email,
      'name': name
    });

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }
}

final findClientAction = FindClientAction(MsgType.FINDCLIENT);
