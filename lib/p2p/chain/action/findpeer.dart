import '../../../entity/p2p/message.dart';
import '../baseaction.dart';

/// 根据目标peerpoint的peerid搜索
class FindPeerAction extends BaseAction {
  FindPeerAction(MsgType msgType) : super(msgType);

  Future<dynamic> findPeer(String targetPeerId) async {
    ChainMessage? chainMessage = await prepareSend({'peerId': targetPeerId});

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

}

final findPeerAction = FindPeerAction(MsgType.FINDPEER);
