import {ChainMessage, MsgType} from '@/libs/p2p/message';
import {BaseAction} from '@/libs/p2p/chain/baseaction';
import {webrtcPeerPool} from '@/libs/transport/webrtc/webrtcpeerpool';

/**
 在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 */
export class SignalAction extends BaseAction {
  constructor(msgType: MsgType) {
    super(msgType);
    webrtcPeerPool.registSignalAction(this);
  }

  async signal(connectPeerId: string, data: any, targetPeerId: string): Promise<any> {
    let chainMessage: ChainMessage = signalAction.prepareSend(connectPeerId, data, targetPeerId);
    // TODO: 视频通话的signal加密送过去解密完数据有问题，具体原因还没找到
    //chainMessage.NeedEncrypt = true

    let response: ChainMessage = await signalAction.send(chainMessage);
    if (response) {
      return response.Payload;
    }

    return null;
  }

  async receive(chainMessage: ChainMessage): Promise<ChainMessage> {
    let _chainMessage: ChainMessage = await super.receive(chainMessage);
    if (_chainMessage && signalAction.receivers) {
      signalAction.receivers.forEach((receiver, key) => {
        if (_chainMessage) {
          receiver(_chainMessage.SrcPeerId, _chainMessage.SrcConnectPeerId, _chainMessage.SrcConnectSessionId, _chainMessage.Payload);
        }
      });

      return null;
    }
  }
}

export let signalAction = new SignalAction(MsgType.SIGNAL);
