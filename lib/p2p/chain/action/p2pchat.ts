import {ChainMessage, MsgType} from '@/libs/p2p/message';
import {BaseAction, PayloadType} from '@/libs/p2p/chain/baseaction';
import {dataBlockService} from '@/libs/p2p/chain/datablock';

/**
 在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 */
export class P2pChatAction extends BaseAction {
  constructor(msgType: MsgType) {
    super(msgType);
  }

  async chat(connectPeerId: string, data: any, targetPeerId: string): Promise<any> {
    let chainMessage: ChainMessage = this.prepareSend(connectPeerId, data, targetPeerId);
    // 已经使用signal protocol加密，不用再加密
    //chainMessage.NeedEncrypt = true
    //chainMessage.NeedSlice = true
    let response: ChainMessage = await this.send(chainMessage);
    if (response) {
      return response;
    }

    return null;
  }

  async receive(chainMessage: ChainMessage): Promise<ChainMessage> {
    let _chainMessage = await super.receive(chainMessage);
    let srcPeerId: string = chainMessage.SrcPeerId;
    let payload: string;
    if (_chainMessage.PayloadType === PayloadType.DataBlock) {
      let _dataBlock = _chainMessage.Payload;
      await dataBlockService.decrypt(_dataBlock);
      payload = _dataBlock.payload;
    } else {
      payload = chainMessage.Payload;
    }
    if (chainMessage && p2pChatAction.receivers) {
      p2pChatAction.receivers.forEach(async (receiver, key) => {
        await receiver(srcPeerId, payload);
      });
      return null;
    }
  }
}

export let p2pChatAction = new P2pChatAction(MsgType.P2PCHAT);
