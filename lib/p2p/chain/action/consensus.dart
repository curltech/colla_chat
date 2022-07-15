import '../../../entity/p2p/message.dart';
import '../baseaction.dart';
import '../chainmessagehandler.dart';

///
class ConsensusAction extends BaseAction {
  ConsensusAction(MsgType msgType) : super(msgType) {
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS.name, send, receive, response);
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS_RAFT.name, send, receive, response);
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS_PBFT.name, send, receive, response);
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS_REPLY.name, send, receive, response);
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS_RAFT_REPLY.name, send, receive, response);
    chainMessageDispatch.registerChainMessageHandler(
        MsgType.CONSENSUS_PBFT_REPLY.name, send, receive, response);
  }

  Future<dynamic?> consensus(dynamic dataBlock, {String? msgType}) async {
    ChainMessage chainMessage = await prepareSend(dataBlock);
    chainMessage.payloadType = PayloadType.dataBlock.name;
    msgType ??= MsgType.CONSENSUS.name;
    chainMessage.messageType = msgType;

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.payload;
    }

    return null;
  }

  @override
  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    ChainMessage? chainMessage_ = await super.receive(chainMessage);
    if (chainMessage_ != null && consensusAction.receivers.isNotEmpty) {
      consensusAction.receivers.forEach((String key, dynamic receiver) async =>
          {await receiver(chainMessage_)});

      return null;
    }

    return null;
  }
}

final consensusAction = ConsensusAction(MsgType.CONSENSUS);
