import { ChainMessage, MsgType } from '../message';
import { BaseAction } from '../baseaction';
export declare class ChatMessageType {
    static LOGOUT: string;
    static MIGRATE: string;
    static BACKUP: string;
    static RESTORE: string;
}
/**
在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
*/
export declare class ChatAction extends BaseAction {
    constructor(msgType: MsgType);
    chat(connectPeerId: string, data: any, targetPeerId: string): Promise<any>;
    receive(chainMessage: ChainMessage): ChainMessage;
}
export declare let chatAction: ChatAction;
