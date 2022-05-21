import {BaseService, StatusEntity} from '@/libs/datastore/base';

export class ConsensusLog extends StatusEntity {
  public blockId!: string;
  public blockType!: string;
  /**
   * 数据块的本条分片是交易负载的第几个分片，在没有分片前是1，分片后>=1，但是<=sliceSize
   */
  public sliceNumber!: number;
  /**
   * 双方的公钥不能被加密传输，因为需要根据公钥决定配对的是哪一个版本的私钥
   * 对方的公钥有可能不存在，这时候数据没有加密，对称密钥也不存在
   * 自己的公钥始终存在，因此签名始终可以验证
   */
  public peerId!: string;
  public publicKey!: string;
  public address!: string;
  // 请求的排好序的序号
  public primarySequenceId!: number;
  /**
   * primary peer
   */
  public primaryPeerId!: string;
  public primaryPublicKey!: string;
  public primaryAddress!: string;
  /**
   * client
   */
  public clientPeerId!: string;
  public clientPublicKey!: string;
  public clientAddress!: string;
  /**
   * 块负载的hash，是负载的decode64 hash，然后encode64
   */
  public payloadHash!: string;
  public transactionAmount!: number;
  public peerIds!: string;
  // 请求的结果状态
  public responseStatus!: string;
}

export class ConsensusLogService extends BaseService {

}

export let consensusLogService = new ConsensusLogService("blc_consensuslog", [], []);
