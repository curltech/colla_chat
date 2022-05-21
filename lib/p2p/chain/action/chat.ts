import {ChainMessage, MsgType} from '@/libs/p2p/message';
import {BaseAction} from '@/libs/p2p/chain/baseaction';

// Socket消息类型
export class ChatMessageType {
  static LOGOUT = 'LOGOUT';
  static MIGRATE = 'MIGRATE';
  static BACKUP = 'BACKUP';
  static RESTORE = 'RESTORE';
}

/**
 在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
 */
export class ChatAction extends BaseAction {
  constructor(msgType: MsgType) {
    super(msgType);
  }

  async chat(connectPeerId: string, data: any, targetPeerId: string): Promise<any> {
    let chainMessage: ChainMessage = this.prepareSend(connectPeerId, data, targetPeerId);
    chainMessage.NeedEncrypt = true;

    let response: ChainMessage = await this.send(chainMessage);
    if (response) {
      return response.Payload;
    }

    return null;
  }

  async receive(chainMessage: ChainMessage): Promise<ChainMessage> {
    let _chainMessage: ChainMessage = await super.receive(chainMessage);
    if (_chainMessage && chatAction.receivers) {
      chatAction.receivers.forEach(async (receiver, key) => {
        if (_chainMessage) {
          await receiver(_chainMessage.Payload);
        }
      });

      return null;
    }
  }
}

export let chatAction = new ChatAction(MsgType.CHAT);
