import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';

///
class ConsensusAction extends BaseAction {
  ConsensusAction(MsgType msgType) : super(msgType);

  Future<bool> consensus(dynamic dataBlock, {String? msgType}) async {
    ChainMessage chainMessage = await prepareSend(dataBlock);
    chainMessage.payloadType = PayloadType.dataBlock.name;
    msgType ??= MsgType.CONSENSUS.name;
    chainMessage.messageType = msgType;

    return await send(chainMessage);
  }
}

final consensusAction = ConsensusAction(MsgType.CONSENSUS);
