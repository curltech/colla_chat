import {BaseService, StatusEntity} from '@/libs/datastore/base';
import {TransactionKey} from '@/libs/p2p/chain/transactionkey';
import {myself} from '@/libs/p2p/dht/myselfpeer';
import {openpgp} from '@/libs/crypto/openpgp';
import {messageSerializer} from '@/libs/tool/message';
import {ObjectUtil, TypeUtil} from '@/libs/tool/util';
import {merkleTree} from '@/libs/crypto/merkletree';
import {PeerClient, peerClientService} from '@/libs/p2p/dht/peerclient';
import {queryValueAction} from '@/libs/p2p/chain/action/queryvalue';

const SliceLimit = 1024 * 1024 * 1024;

export class DataBlock extends StatusEntity {
  public blockId!: string;
  public parentBusinessNumber!: string;
  public businessNumber!: string;
  public blockType!: string;
  /**
   * 双方的公钥不能被加密传输，因为需要根据公钥决定配对的是哪一个版本的私钥
   * 对方的公钥有可能不存在，这时候数据没有加密，对称密钥也不存在
   * 自己的公钥始终存在，因此签名始终可以验证
   */
  public peerId!: string;
  public publicKey!: string;
  public address!: string;
  public securityContext!: string;
  /**
   * 经过源peer的公钥加密过的对称密钥，这个对称密钥是随机生成，每次不同，用于加密payload
   *
   * 如果本字段不为空，表示负载被加密了，至少是只有源peer能够解密
   *
   * 这样处理的好处是判断是否加密只需datablock，而且如果只是源peer的收藏，则transactionkey为空
   */
  public payload!: any;
  public payloadKey!: string;
  public transportPayload!: string;
  /**
   * transactionKeys的寄送格式，每个交易的第一个分片有数据，保证每个交易可以单独被查看
   */
  public transportKey!: string;
  /**
   * 本数据块的负载被拆成分片的总数，在没有分片前是1，分片后>=1，同一交易负载的交易号相同
   */
  public sliceSize!: number;
  /**
   * 数据块的本条分片是交易负载的第几个分片，在没有分片前是1，分片后>=1，但是<=sliceSize
   */
  public sliceNumber!: number;
  /**
   * 负载源peer的签名
   */
  public signature!: string;
  /**
   * 块负载的hash，是负载的decode64 hash，然后encode64
   */
  public payloadHash!: string;
  public transactionAmount!: number;
  // 由区块提议者填充的时间戳
  public createTimestamp!: number;
  public expireDate!: number;
  /**
   * 当在一个事务中的一批交易开始执行的时候，首先保存交易，状态是Draft，
   *
   * 交易在共识后真正执行完毕状态变为effective，生成blockId
   *
   * 交易被取消，状态变成Ineffective
   */
    // 请求的排好序的序号
  public primarySequenceId!: number;
  /**
   * 分片hash汇总到交易，交易汇总到块hash
   */
  public stateHash!: string;
  public previousBlockId!: string;
  // 前一个区块的全局hash，也就是0:0的stateHash
  public previousBlockHash!: string;
  // 共识可能会引入的一些可选的元数据
  public metadata!: string;
  public name: string;
  public description: string;
  public thumbnail: string;
  public mimeType!: string;
  public transactionKeys!: TransactionKey[];
  /**
   * 是负载的decode64 signature，然后encode64
   */
  public transactionKeySignature!: string;
  /**
   * chainApp
   */
  public chainAppPeerId!: string;
  public chainAppPublicKey!: string;
  public chainAppAddress!: string;

  /**
   * primary peer
   */
  public primaryPeerId!: string;
  public primaryPublicKey!: string;
  public primaryAddress!: string;

  public peerIds!: string;
}

export class BlockType {
  // 聊天
  static P2pChat = 'P2pChat';
  // 聊天附件
  static ChatAttach = 'ChatAttach';
  // 收藏
  static Collection = 'Collection';
  // 群文件
  static GroupFile = 'GroupFile';
  // 频道
  static Channel = 'Channel';
  // 频道文章
  static ChannelArticle = 'ChannelArticle';
}

export class DataBlockService extends BaseService {
  static create(blockId: string, parentBusinessNumber: string, businessNumber: string, blockType: string, createTimestamp: number, payload: any, peers: PeerClient[]): DataBlock {
    let dataBlock = new DataBlock();
    dataBlock.blockId = blockId;
    dataBlock.parentBusinessNumber = parentBusinessNumber;
    dataBlock.businessNumber = businessNumber;
    dataBlock.blockType = blockType;
    dataBlock.createTimestamp = createTimestamp;
    if (payload) {
      dataBlock.payload = payload.payload;
      dataBlock.metadata = payload.metadata;
      dataBlock.thumbnail = payload.thumbnail;
      dataBlock.name = payload.name;
      dataBlock.description = payload.description;
      dataBlock.expireDate = payload.expireDate;
      dataBlock.mimeType = payload.mimeType;
    }
    if (peers && peers.length > 0) {
      let transactionKeys = [];
      for (let peer of peers) {
        let transactionKey = new TransactionKey();
        transactionKey.blockId = blockId;
        transactionKey.peerId = peer.peerId;
        transactionKey.publicKey = peer.publicKey;
        transactionKeys.push(transactionKey);
      }
      dataBlock.transactionKeys = transactionKeys;
    }

    return dataBlock;
  }

  /**
   * 加密后，传输前分片，对每个交易单独进行分片，可以多线程同步传输
   *
   * @param dataBlock
   * @return []
   */
  static async slice(dataBlock: DataBlock): Promise<DataBlock[]> {
    let sliceSize = dataBlock.sliceSize;
    let dataBlocks: DataBlock[] = [];
    /**
     * 只有在没有分片的情况下才能分片
     */
    if (!sliceSize) {
      // 对每一个块分片
      let sliceHashs = [];
      let slice0 = null;
      let transportPayload = dataBlock.transportPayload;
      let expireDate = dataBlock.expireDate;
      let mimeType = dataBlock.mimeType;
      let db: DataBlock;
      let slicePayload = null;
      if (transportPayload && transportPayload.length > SliceLimit) {
        sliceSize = transportPayload.length / SliceLimit;
        sliceSize = Math.ceil(sliceSize);
        for (let i = 0; i < sliceSize; ++i) {
          // 第一个分片
          if (i === 0) {
            db = dataBlock;
            slice0 = db;
          } else { // 第n个分片
            db = new DataBlock();
            ObjectUtil.copy(dataBlock, db);
            db.transportKey = undefined;
            db.stateHash = undefined;
          }
          db.sliceNumber = i + 1;
          db.sliceSize = sliceSize;
          db.expireDate = expireDate;
          db.mimeType = mimeType;
          if (i === sliceSize - 1) {
            slicePayload = transportPayload.substring(i * SliceLimit, transportPayload.length);
          } else {
            slicePayload = transportPayload.substring(i * SliceLimit, (i + 1) * SliceLimit);
          }
          db.transportPayload = slicePayload;
          // 每个块的负载计算hash
          await DataBlockService.sign(db);
          dataBlocks.push(db);
          sliceHashs.push(db.payloadHash);
        }
      } else {
        dataBlock.sliceNumber = 1;
        dataBlock.sliceSize = 1;
        // 每个块的负载计算hash
        await DataBlockService.sign(dataBlock);
        dataBlocks.push(dataBlock);
        sliceHashs.push(dataBlock.payloadHash);
      }
      //每个交易分片结束
      if (sliceHashs.length > 0) {
        let stateHashs = await merkleTree.buildStringTree(sliceHashs);
        if (slice0) {
          slice0.stateHash = openpgp.encodeBase64(stateHashs[stateHashs.length - 1]);
        }
      }
    }

    return dataBlocks;
  }

  static async sign(dataBlock: DataBlock) {
    let privateKey = myself.privateKey;
    if (!privateKey) {
      throw new Error("NullPrivateKey");
    }
    let signatureData: string;
    let transportPayload = dataBlock.transportPayload;
    if (transportPayload) {
      // 设置数据的hash
      let payloadHash = await openpgp.hash(transportPayload);
      dataBlock.payloadHash = openpgp.encodeBase64(payloadHash);
      signatureData = transportPayload;
    } else {
      dataBlock.expireDate = new Date().getTime();
      signatureData = dataBlock.expireDate + dataBlock.peerId;
    }
    // 设置签名
    let signature = await openpgp.sign(signatureData, privateKey);
    dataBlock.signature = signature;
  }

  static async verify(dataBlock: DataBlock) {
    // 消息的数据部分，验证签名
    let peerId = dataBlock.peerId;
    let transportPayload = dataBlock.transportPayload;
    let signature = dataBlock.signature;
    if (transportPayload && peerId === myself.myselfPeer.peerId) {
      let srcPublicKey = myself.publicKey;
      let pass = await openpgp.verify(transportPayload, signature, srcPublicKey);
      if (!pass) {
        let i = 0;
        while (!pass && i < myself.expiredKeys.length) {
          pass = await openpgp.verify(transportPayload, signature, myself.expiredKeys[i].expiredPublicKey);
          i++;
        }
        if (!pass) {
          console.error("TransportPayloadVerifyFailure");
          //throw new Error("TransportPayloadVerifyFailure")
        }
      }
    } else {
      let srcPublicKey = await peerClientService.getPublic(peerId);
      if (!srcPublicKey) {
        throw new Error("NullSrcPublicKey");
      }
      if (transportPayload) {
        let pass = await openpgp.verify(transportPayload, signature, srcPublicKey);
        if (!pass) {
          console.error("TransportPayloadVerifyFailure");
          //throw new Error("TransportPayloadVerifyFailure")
        }
      }
    }
  }

  /**
   * 按照blockId分组
   * @param dbs
   */
  static group(dbs: DataBlock[]): any {
    if (dbs && dbs.length > 0) {
      let dbMap: any = {};
      for (let db of dbs) {
        let blockId = db.blockId;
        let blocks: DataBlock[];
        if (!dbMap[blockId]) {
          blocks = [];
          dbMap[blockId] = blocks;
        } else {
          blocks = dbMap[blockId];
        }
        blocks.push(db);
      }
      return dbMap;
    }

    return null;
  }

  /**
   * 假设输入数组的blockId相同
   * @param {*} dataBlocks
   */
  static async merge(dataBlocks: DataBlock[]): Promise<DataBlock> {
    if (dataBlocks && dataBlocks.length > 0) {
      let sliceSize = dataBlocks[0].sliceSize;
      if (dataBlocks.length !== sliceSize) {
        throw new Error('ErrorSize');
      }
      dataBlocks.sort(function (a, b) {
        return a.sliceNumber - b.sliceNumber;
      });
      let transportPayload: string;
      let ps = [];
      for (let i = 0; i < dataBlocks.length; ++i) {
        let dataBlock = dataBlocks[i];
        let sliceNumber = dataBlock.sliceNumber;
        if (i + 1 !== sliceNumber) {
          throw new Error('ErrorSliceNumber');
        }
        let promise = new Promise(async function (resolve, reject) {
          await DataBlockService.verify(dataBlock);
          // 还原交易分片数据
          if (dataBlock.transportPayload) {
            resolve(dataBlock.transportPayload);
          } else {
            resolve(null);
          }
          dataBlock.transportPayload = undefined;
        });
        ps.push(promise);
      }
      let slicePayloads: any[] = await Promise.all(ps);
      if (slicePayloads && slicePayloads.length > 0) {
        for (let slicePayload of slicePayloads) {
          if (slicePayload) {
            if (!transportPayload) {
              transportPayload = slicePayload;
            } else {
              transportPayload = transportPayload + slicePayload;
            }
          }
        }
      }
      dataBlocks[0].transportPayload = transportPayload;
      return dataBlocks[0];
    }

    return null;
  }

  /**
   * 客户端加密处理基本的DataBlock数据，加密每个交易的负载
   *
   * 假设基本数据已经存在，但是没有经过加密处理，分片处理，hash处理和签名处理
   */
  async encrypt(dataBlock: DataBlock) {
    // 设置客户端的基本属性
    dataBlock.peerId = myself.myselfPeer.peerId;
    // 设置数据的时间戳
    if (!dataBlock.createTimestamp) {
      dataBlock.createTimestamp = new Date().getTime();
    }
    // 如果有目标接受对象，需要加密处理，生成对称密钥
    let secretKey = null;
    let transactionKeys = dataBlock.transactionKeys;
    // 消息的数据部分转换成字符串，签名，加密，压缩，base64
    let privateKey = myself.privateKey;
    if (!privateKey) {
      throw new Error("NullPrivateKey");
    }
    if (transactionKeys && transactionKeys.length > 0) {
      secretKey = await openpgp.getRandomAsciiString();
      // 处理目标的加密密钥
      for (let transactionKey of transactionKeys) {
        // 对对称密钥进行公钥加密
        let targetPublicKey = null;
        if (transactionKey.peerId === myself.myselfPeer.peerId) {
          targetPublicKey = myself.publicKey;
        } else {
          targetPublicKey = await peerClientService.getPublic(transactionKey.peerId);
        }
        if (!targetPublicKey) {
          console.warn("TargetPublicKey is null, will not be encrypted!");
          continue;
        }
        let secretKeyData = await openpgp.eccEncrypt(secretKey, targetPublicKey, null);
        transactionKey.payloadKey = secretKeyData;
        if (transactionKey.peerId === dataBlock.peerId) {
          dataBlock.payloadKey = transactionKey.payloadKey;
        }
      }
      // 设置目标签名
      let keyData = messageSerializer.marshal(dataBlock.transactionKeys);
      let keySignData = await openpgp.sign(keyData, privateKey);
      dataBlock.transactionKeySignature = keySignData;
      dataBlock.transportKey = openpgp.encodeBase64(keyData);
      dataBlock.transactionKeys = undefined; // NOTE:上线前注释掉方便调试
    }
    // 对业务数据进行处理
    let transportPayload = dataBlock.transportPayload;
    if (!transportPayload) {
      let payload = dataBlock.payload;
      if (payload) {
        transportPayload = messageSerializer.textMarshal(payload);
      }
    }
    if (transportPayload) {
      let data: Uint8Array = openpgp.stringToUtf8Uint8Array(transportPayload);
      // 压缩原始数据
      data = openpgp.compress(data);
      // 对数据进行对称加密
      if (secretKey) {
        data = await openpgp.aesEncrypt(data, secretKey);
      }
      // 最终的数据放入
      dataBlock.transportPayload = openpgp.encodeBase64(data);
    }
    dataBlock.payload = null; // NOTE:上线前注释掉方便调试
  }

  /**
   * 接受者解密（如果加密的化），在分片合并，校验DataBlock数据后执行解密
   */
  async decrypt(dataBlock: DataBlock, options = {verify: true}) {
    let transactionKeys = dataBlock.transactionKeys;
    if (!transactionKeys && dataBlock.transportKey) {
      let transportKey = openpgp.decodeBase64(dataBlock.transportKey);
      if (transportKey) {
        // Keys，验证签名
        let keySignature = dataBlock.transactionKeySignature;
        if (keySignature && options.verify === true) {
          if (dataBlock.peerId === myself.myselfPeer.peerId) {
            let srcPublicKey = myself.publicKey;
            let pass = await openpgp.verify(transportKey, keySignature, srcPublicKey);
            if (!pass) {
              let i = 0;
              while (!pass && i < myself.expiredKeys.length) {
                pass = await openpgp.verify(transportKey, keySignature, myself.expiredKeys[i].expiredPublicKey);
                i++;
              }
              if (!pass) {
                console.error("TransactionKeyVerifyFailure");
                //throw new Error("TransactionKeyVerifyFailure")
              }
            }
          } else {
            let srcPublicKey = await peerClientService.getPublic(dataBlock.peerId);
            if (!srcPublicKey) {
              throw new Error("NullSrcPublicKey");
            }
            let pass = await openpgp.verify(transportKey, keySignature, srcPublicKey);
            if (!pass) {
              console.error("TransactionKeyVerifyFailure");
              //throw new Error("TransactionKeyVerifyFailure")
            }
          }
        }
        transactionKeys = messageSerializer.unmarshal(transportKey);
        dataBlock.transactionKeys = transactionKeys;
      }
    }
    // 如果数据被加密，处理目标的加密密钥
    let secretKey = null;
    if (transactionKeys && transactionKeys.length > 0) {
      for (let transactionKey of transactionKeys) {
        // 找到正确的公钥
        if (transactionKey.peerId === myself.myselfPeer.peerId) {
          let payloadKey = transactionKey.payloadKey;
          if (payloadKey) {
            let privateKey = myself.privateKey;
            if (!privateKey) {
              throw new Error("NullPrivateKey");
            }
            try {
              secretKey = await openpgp.eccDecrypt(payloadKey, null, privateKey);
            } catch (e) {
              console.log(e);
            }
            let i = 0;
            while (!secretKey && i < myself.expiredKeys.length) {
              try {
                secretKey = await openpgp.eccDecrypt(payloadKey, null, myself.expiredKeys[i].expiredPrivateKey);
              } catch (e) {
                console.log(e);
              } finally {
                i++;
              }
            }
            if (!secretKey) {
              throw new Error("EccDecryptFailed");
            }
          }
        }
      }
    }
    // 处理数据
    let transportPayload = dataBlock.transportPayload;
    if (transportPayload) {
      let data: Uint8Array = openpgp.decodeBase64(transportPayload);
      // 数据解密
      if (secretKey) {
        try {
          data = await openpgp.aesDecrypt(data, secretKey);
        } catch (err) {
          console.error('data cannot aesDecrypt');
          data = undefined;
        }
      }
      let payload = null;
      if (data) {
        // 解压缩
        data = openpgp.uncompress(data);
        // 还原数据
        let str: string = openpgp.utf8Uint8ArrayToString(data);
        payload = messageSerializer.textUnmarshal(str);
      }
      dataBlock.payload = payload;
      dataBlock.transportPayload = undefined;
    }
  }

  async blockMerge(dbMap: any) {
    let blocks = [];
    if (dbMap) {
      // 每个不同的块号循环
      for (let key in dbMap) {
        let dataBlocks = dbMap[key];
        if (dataBlocks && TypeUtil.isArray(dataBlocks) && dataBlocks.length > 0) {
          let db = await DataBlockService.merge(dataBlocks);
          if (db) {
            await this.decrypt(db);
          }
          blocks.push(db);
        }
      }
    }
    return blocks;
  }

  async blockMapMerge(targetMap: any, dbMap: any) {
    if (dbMap) {
      let blocks = [];
      // 每个不同的块号循环
      for (let key in dbMap) {
        let ts = targetMap[key];
        if (!ts) {
          ts = [];
          targetMap[key] = ts;
        }
        let dataBlocks = dbMap[key];
        if (dataBlocks && TypeUtil.isArray(dataBlocks) && dataBlocks.length > 0) {
          for (let dataBlock of dataBlocks) {
            ts.push(dataBlock);
          }
        }
      }
    }
  }

  /**
   * 最基本的根据条件查询block的操作，返回满足条件的block的Map
   *
   * @param {*} connectPeerId
   * @param {*} conditionBean
   * @param {*} options
   */
  async _find(connectPeerId: string, conditionBean: any = {}, options = {createPeer: false, receiverPeer: true}) {
    let blockMap: any;
    conditionBean['receiverPeerId'] = myself.myselfPeer.peerId;
    if (options) {
      if (options.createPeer === true) {
        conditionBean['createPeerId'] = myself.myselfPeer.peerId;
      }
      if (options.receiverPeer === true) {
        conditionBean['receiverPeer'] = true;
      }
    }
    let blocks = await queryValueAction.queryValue(connectPeerId, conditionBean);
    if (blocks && TypeUtil.isArray(blocks)) {
      blockMap = DataBlockService.group(blocks);
    }

    return blockMap;
  }

  async loadUrl(url: string, uriVariables: any) {
    let html;

    return html;
  }

  /**
   * 获取块中的负载
   *
   * @param {*} dataBlocks
   */
  getPayload(dataBlocks: any[]) {
    if (dataBlocks && dataBlocks.length > 0) {
      let data = [];
      // 循环不同的块号
      for (let dataBlock of dataBlocks) {
        if (dataBlock.blockType === BlockType.P2pChat) {
          data.push(dataBlock);
        } else {
          let d = dataBlock.payload;
          if (d) {
            d.blockId = dataBlock.blockId;
            d.sliceNumber = dataBlock.sliceNumber;
            d.sliceSize = dataBlock.sliceSize;
            data.push(d);
          }
        }
      }
      return data;
    }

    return null;
  }

  /**
   * 根据块号从云端获取全部分片数据
   *
   * 返回block的Map
   *
   * @param {*} connectPeerId
   * @param {*} blockId
   */
  async findTx(connectPeerId: string, blockId: string) {
    let start = new Date().getTime();
    /**
     * 首先获取所有交易的第1个分片
     */
    let blockMap = await this._find(connectPeerId, {blockId: blockId, sliceNumber: 1});
    if (blockMap) {
      let block = blockMap[blockId];
      if (block) {
        let sliceSize = block[0].sliceSize;
        console.log('blockId:' + blockId + ';sliceSize:' + sliceSize);
        if (sliceSize && sliceSize > 1) {
          let ps = [];
          /**
           * 获取第一个分片以后的分片
           */
          for (let i = 2; i <= sliceSize; ++i) {
            let promise = this._find(connectPeerId, {blockId: blockId, sliceNumber: i});
            ps.push(promise);
          }
          let blocks = await Promise.all(ps);
          /**
           * 合并所有的分片
           */
          if (blocks && blocks.length > 0) {
            for (let bs of blocks) {
              await this.blockMapMerge(blockMap, bs);
            }
          }
        }
      }
    }
    let end = new Date().getTime();
    console.log('findTx blockId:' + blockId + ';time:' + (end - start));

    return blockMap;
  }

  /**
   * 根据块号从云端获取全部分片数据的合并负载
   *
   * 返回block的payload
   *
   * @param {*} connectPeerId
   * @param {*} blockId
   */
  async findTxPayload(connectPeerId: string, blockId: string) {
    let start = new Date().getTime();
    let blockMap = await this.findTx(connectPeerId, blockId);
    let dataBlocks = await this.blockMerge(blockMap);
    let data = this.getPayload(dataBlocks);
    let end = new Date().getTime();
    console.log('findTxPayload connectPeerId:' + connectPeerId + ';blockId:' + blockId + ';time:' + (end - start));

    return data;
  }
}

export let dataBlockService = new DataBlockService("blc_dataBlock", [], []);
