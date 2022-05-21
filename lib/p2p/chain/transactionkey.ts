import {BaseEntity, BaseService} from '@/libs/datastore/base';

export class TransactionKey extends BaseEntity {
  /**
   * 经过目标peer的公钥加密过的对称密钥，这个对称密钥是随机生成，每次不同，用于加密payload
   */
  public blockId!: string;
  public peerId!: string;
  /**
   key是blockId:peerId，用于key检索和存储
   */
  public key!: string;
  public payloadKey!: string;
  public publicKey!: string;
  public address!: string;
  public peerType!: string;
}

export class TransactionKeyService extends BaseService {
}

export let transactionKeyService = new TransactionKeyService("blc_transactionKey", [], []);
