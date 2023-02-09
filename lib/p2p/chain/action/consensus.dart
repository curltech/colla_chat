import '../../../entity/p2p/chain_message.dart';
import '../baseaction.dart';
import '../chainmessagehandler.dart';

///
class ConsensusAction extends BaseAction {
  ConsensusAction(MsgType msgType) : super(msgType) {
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS.name, receive, response);
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS_RAFT.name, receive, response);
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS_PBFT.name, receive, response);
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS_REPLY.name, receive, response);
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS_RAFT_REPLY.name, receive, response);
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS_PBFT_REPLY.name, receive, response);
  }

  Future<bool> consensus(dynamic dataBlock, {String? msgType}) async {
    ChainMessage chainMessage = await prepareSend(dataBlock);
    chainMessage.payloadType = PayloadType.dataBlock.name;
    msgType ??= MsgType.CONSENSUS.name;
    chainMessage.messageType = msgType;

    return await send(chainMessage);
  }
}

final consensusAction = ConsensusAction(MsgType.CONSENSUS);
