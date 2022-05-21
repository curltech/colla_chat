import {ChainMessage, MsgType} from '@/libs/p2p/message';
import {BaseAction} from '@/libs/p2p/chain/baseaction';

/**
 在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 Ping只是一个演示，适合点对点的通信，这种方式灵活度高，但是需要自己实现全网遍历的功能
 chat就可以采用这种方式
 */
class QueryPeerTransAction extends BaseAction {
  constructor(msgType: MsgType) {
    super(msgType);
  }

  async queryPeerTrans(connectPeerId: string, data: any): Promise<any[]> {
    let chainMessage: ChainMessage = this.prepareSend(connectPeerId, data, null);

    let response: ChainMessage = await this.send(chainMessage);
    if (response) {
      return response.Payload;
    }

    return null;
  }
}

export let queryPeerTransAction = new QueryPeerTransAction(MsgType.QUERYPEERTRANS);
