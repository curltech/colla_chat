import { ChainMessage, MsgType } from '../message';
import { BaseAction } from '../baseaction';
/**
在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
*/
export declare class IonSignalAction extends BaseAction {
    constructor(msgType: MsgType);
    signal(connectPeerId: string, data: any, targetPeerId: string): Promise<any>;
    receive(chainMessage: ChainMessage): ChainMessage;
}
export declare let ionSignalAction: IonSignalAction;
