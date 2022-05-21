import { MsgType } from '../message';
import { BaseAction } from '../baseaction';
/**
在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
Ping只是一个演示，适合点对点的通信，这种方式灵活度高，但是需要自己实现全网遍历的功能
chat就可以采用这种方式
*/
declare class QueryValueAction extends BaseAction {
    constructor(msgType: MsgType);
    queryValue(connectPeerId: string, data: any): Promise<any[]>;
}
export declare let queryValueAction: QueryValueAction;
export {};
