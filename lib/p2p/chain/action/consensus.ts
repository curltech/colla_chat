import {ChainMessage, MsgType} from '@/libs/p2p/message';
import {BaseAction, PayloadType} from '@/libs/p2p/chain/baseaction';
import {chainMessageDispatch} from '../chainmessagehandler';

/**
 在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 */
export class ConsensusAction extends BaseAction {
  constructor(msgType: MsgType) {
    super(msgType);
    chainMessageDispatch.registChainMessageHandler(MsgType[MsgType.CONSENSUS], this.send, this.receive, this.response);
    chainMessageDispatch.registChainMessageHandler(MsgType[MsgType.CONSENSUS_RAFT], this.send, this.receive, this.response);
    chainMessageDispatch.registChainMessageHandler(MsgType[MsgType.CONSENSUS_PBFT], this.send, this.receive, this.response);
    chainMessageDispatch.registChainMessageHandler(MsgType[MsgType.CONSENSUS_REPLY], this.send, this.receive, this.response);
    chainMessageDispatch.registChainMessageHandler(MsgType[MsgType.CONSENSUS_RAFT_REPLY], this.send, this.receive, this.response);
    chainMessageDispatch.registChainMessageHandler(MsgType[MsgType.CONSENSUS_PBFT_REPLY], this.send, this.receive, this.response);
  }

  async consensus(connectPeerId: string, msgType: string, dataBlock: any): Promise<any> {
    let chainMessage: ChainMessage = this.prepareSend(connectPeerId, dataBlock, undefined);
    chainMessage.PayloadType = PayloadType.DataBlock;
    if (!msgType) {
      msgType = MsgType[MsgType.CONSENSUS];
    }
    chainMessage.MessageType = msgType;

    let response: ChainMessage = await this.send(chainMessage);
    if (response) {
      return response.Payload;
    }

    return null;
  }

  async receive(chainMessage: ChainMessage): Promise<ChainMessage> {
    let _chainMessage = await super.receive(chainMessage);
    if (chainMessage && consensusAction.receivers) {
      consensusAction.receivers.forEach(async (receiver, key) => {
        await receiver(chainMessage);
      });

      return null;
    }
  }
}

export let consensusAction = new ConsensusAction(MsgType.CONSENSUS);
