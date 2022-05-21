import {ChainMessage, MsgType} from '@/libs/p2p/message';
import {BaseAction} from '@/libs/p2p/chain/baseaction';
import {ionSfuClientPool} from '@/libs/transport/ionsfuclient';

/**
 在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 */
export class IonSignalAction extends BaseAction {
  constructor(msgType: MsgType) {
    super(msgType);
    ionSfuClientPool.registSignalAction(this);
  }

  async signal(connectPeerId: string, data: any, targetPeerId: string): Promise<any> {
    let chainMessage: ChainMessage = ionSignalAction.prepareSend(connectPeerId, data, targetPeerId);
    chainMessage.NeedEncrypt = true;

    let response: ChainMessage = await ionSignalAction.send(chainMessage);
    if (response) {
      console.info('IonSignal response:' + JSON.stringify(response));
      return response.Payload;
    }

    return null;
  }

  async receive(chainMessage: ChainMessage): Promise<ChainMessage> {
    let _chainMessage = await super.receive(chainMessage);
    if (_chainMessage && ionSignalAction.receivers) {
      ionSignalAction.receivers.forEach((receiver, key) => {
        if (_chainMessage) {
          receiver(_chainMessage.SrcPeerId, _chainMessage.SrcConnectPeerId, _chainMessage.SrcConnectSessionId, _chainMessage.Payload);
        }
      });

      return null;
    }
  }
}

export let ionSignalAction = new IonSignalAction(MsgType.IONSIGNAL);
