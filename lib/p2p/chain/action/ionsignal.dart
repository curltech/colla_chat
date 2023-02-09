import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/json_util.dart';



/**
    在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 */
class IonSignalAction extends BaseAction {
  IonSignalAction(MsgType msgType) : super(msgType) {
    //ionSfuClientPool.registSignalAction(this);
  }

  Future<bool> signal(dynamic data, String targetPeerId) async {
    ChainMessage? chainMessage =
        await prepareSend(data, targetPeerId: targetPeerId);
    chainMessage.needEncrypt = true;

    return await send(chainMessage);
  }
}

final ionSignalAction = IonSignalAction(MsgType.IONSIGNAL);
