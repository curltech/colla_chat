import { MsgType } from '../message';
import { BaseAction } from '../baseaction';
/**
在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
*/
declare class ConnectAction extends BaseAction {
    constructor(msgType: MsgType);
    connect(connectPeerId: string, peerClient: any): Promise<any>;
}
export declare let connectAction: ConnectAction;
export {};
