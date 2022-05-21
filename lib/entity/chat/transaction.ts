import {BaseService, EntityStatus, BaseEntity, StatusEntity} from "@/libs/datastore/base";

export enum TransactionDataType {
  'PEERTRANSACTION'
}

export let TransactionType = {
  'All': "All",
  'DataBlock': 'DataBlock'
};

export let TransactionStatus = {
  'Effective': 'Effective'
};

export let TargetPeerType = {};

class ChatTransaction extends StatusEntity {
  public sequenceId: string;
  public ownerPeerId: string;
  public amount: number;
  public blockId: string;
  public currency: string;
  public srcPeerBeginBalance: number;
  public srcPeerEndBalance: number;
  public srcPeerId: string;
  public srcPeerType: string;
  public targetPeerBeginBalance: number;
  public targetPeerEndBalance: number;
  public targetPeerId: string;
  public targetPeerType: string;
  public transactionTime: Date;
  public transactionType: string;
}

export class TransactionService extends BaseService {
  async load(condi: any, sort: any, from: number, limit: number) {
    let condition = this.buildCondition(condi, from);

    let data: any;
    if (limit && limit > 0) {
      let page = await this.findPage(condition, sort, null, null, limit);
      data = page.result;
    } else {
      data = await this.find(condition, sort, null, null, null);
    }
    return data;
  }
}

export let transactionService = new TransactionService("chat_transaction", ['ownerPeerId', 'srcPeerId', 'targetPeerId', 'transactionTime', 'transactionType'], []);
