import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

///  在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
///  Ping只是一个演示，适合点对点的通信，这种方式灵活度高，但是需要自己实现全网遍历的功能
///  chat就可以采用这种方式
class PingAction extends BaseAction {
  PingAction(MsgType msgType) : super(msgType);

  Future<bool> ping(dynamic data, String targetPeerId) async {
    ChainMessage chainMessage =
        await prepareSend(data, targetPeerId: targetPeerId);
    //chainMessage.NeedEncrypt = true

    return await send(chainMessage);
  }
}

final pingAction = PingAction(MsgType.PING);
