import '../../message.dart';
import '../baseaction.dart';
import '../chainmessagehandler.dart';

/**
    在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 */
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

  Future<dynamic?> consensus(String connectPeerId, dynamic dataBlock,
      {String? msgType}) async {
    ChainMessage chainMessage = await prepareSend(connectPeerId, dataBlock);
    chainMessage.PayloadType = PayloadType.DataBlock.name;
    if (msgType == null) {
      msgType = MsgType.CONSENSUS.name;
    }
    chainMessage.MessageType = msgType;

    ChainMessage? response = await send(chainMessage);
    if (response != null) {
      return response.Payload;
    }

    return null;
  }

  @override
  Future<ChainMessage?> receive(ChainMessage chainMessage) async {
    ChainMessage? _chainMessage = await super.receive(chainMessage);
    if (_chainMessage != null && consensusAction.receivers.isNotEmpty) {
      consensusAction.receivers.forEach((String key, dynamic receiver) async =>
          {await receiver(_chainMessage)});

      return null;
    }

    return null;
  }
}

final consensusAction = ConsensusAction(MsgType.CONSENSUS);
