/**
 * 我的收藏的定义
 */
import {BaseService, EntityStatus, BaseEntity} from "@/libs/datastore/base";
import {EntityState} from '@/libs/datastore/datastore';
import {myself} from '@/libs/p2p/dht/myselfpeer';
import {SecurityPayload} from '@/libs/p2p/payload';

export let CollectionDataType = {
  'COLLECTION': 'COLLECTION',
  'ATTACH': 'ATTACH',
  'COLLECTION_TAGCOLLECTION': 'COLLECTION_TAGCOLLECTION',
  'BLOCKLOG': 'BLOCKLOG'
};

let tables = {
  'COLLECTION': 'myCollection',
  'ATTACH': 'myAttach',
  'COLLECTION_TAGCOLLECTION': 'collectionTagCollection',
  'BLOCKLOG': 'blockLog'
};

export let SrcChannelType = {
  'CHAT': 'CHAT',
  'GROUP_CHAT': 'GROUP_CHAT'
};

export let SrcEntityType = {
  'MYSELF': 'MYSELF',
  'LINKMAN': 'LINKMAN'
};

export let CollectionType = {
  'ALL': 'All',
  'IMAGE': 'Image',
  'TEXT': 'Text',
  'FILE': 'File',
  'AUDIO': 'Audio',
  'VIDEO': 'Video',
  'CARD': 'Card',
  'NOTE': 'Note',
  'CHAT': 'Chat',
  'LINK': 'Link',
  'VOICE': 'Voice',
  'POSITION': 'Position'
};

export class Collection extends BaseEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  /**
   * 收藏的类型, note, image, link, file, video, audio, voice, chat, position, card, text
   */
  public collectionType: string;
  /**
   * 内容，作者，标题
   */
  public content: string;
  public plainContent: string;
  public pyPlainContent: string;
  public title: string;
  /**
   * 收藏来源渠道类型，来源渠道ID，来源渠道名称，来源对象类型，来源对象ID，来源对象名称
   */
  public srcChannelType: string;
  public srcChannelId: string;
  public srcChannelName: string;
  public srcEntityType: string;
  public srcEntityId: string;
  public srcEntityName: string;
  /**
   * 收藏的数据块的编号和数据交易编号
   */
  public blockId: string;
  /**
   * 缩略图
   */
  public thumbnail: string;
  public thumbType: string;
  public contentTitle: string;
  public contentBody: string;
  public firstFileInfo: string;
  public firstAudioDuration: string;
  public contentIVAmount: number;
  public contentAAmount: number;
  public attachIVAmount: number;
  public attachAAmount: number;
  public attachOAmount: number;
  public attachAmount: number;
  /**
   * 其它信息
   */
  public attachs: string;
  public payloadKey: string;
  public payloadHash: string;
  public signature: string;
  public versionFlag: string;
  public primaryPeerId: string;
}

export class CollectionService extends BaseService {
  async load(condi: any, from: number, limit: number) {
    let condition: any = {};
    let qs = [];
    if (from && from > 0) {
      qs.push({updateDate: {$lt: from}});
    } else {
      qs.push({updateDate: {$gt: null}});
    }
    if (condi.ownerPeerId) {
      let q: any = {};
      q['ownerPeerId'] = condi.ownerPeerId;
      qs.push(q);
    }
    if (condi.collectionType && condi.collectionType !== CollectionType.ALL) {
      let q: any = {};
      q['collectionType'] = condi.collectionType;
      qs.push(q);
    }
    if (condi.searchTag) {
      let originCondition: any = {};
      originCondition.ownerPeerId = condi.ownerPeerId;
      originCondition.tag = condi.searchTag;
      let ctcs = await collectionTagService.seek(originCondition);
      if (ctcs && ctcs.length > 0) {
        let q: any = {};
        let collectionIdArr = [];
        for (let ctc of ctcs) {
          collectionIdArr.push(ctc.collectionId);
        }
        q['_id'] = {$in: collectionIdArr};
        qs.push(q);
      }
    }
    if (condi.searchText) {
      let subcondition: any = {};
      let subqs = [];
      let q1: any = {};
      let originCondition: any = {};
      originCondition.ownerPeerId = condi.ownerPeerId;
      originCondition.searchText = condi.searchText;
      let ctcs = await collectionTagService.seek(originCondition);
      if (ctcs && ctcs.length > 0) {
        let collectionIdArr = [];
        for (let ctc of ctcs) {
          collectionIdArr.push(ctc.collectionId);
        }
        q1['_id'] = {$in: collectionIdArr};
        subqs.push(q1);
      }
      let q2: any = {};
      q2['plainContent'] = {$regex: condi.searchText};
      subqs.push(q2);
      let q3: any = {};
      q3['pyPlainContent'] = {$regex: condi.searchText};
      subqs.push(q3);
      subcondition['$or'] = subqs;
      qs.push(subcondition);
    }
    qs.push({updateDate: {$gt: null}});
    if (qs.length > 0) {
      condition['$and'] = qs;
    }
    console.log('will load more data, collectionType:' + condi.collectionType + ', searchText:' + condi.searchText);
    //let start = new Date().getTime()
    let data = await this.find(condition, [{updateDate: 'desc'}], null, null, limit);
    //let end = new Date().getTime()
    //console.log('collection findPage time:' + (end - start))
    if (data && data.length > 0) {
      let securityParams: any = {};
      securityParams.NeedCompress = true;
      securityParams.NeedEncrypt = true;
      for (let d of data) {
        let payloadKey = d.payloadKey;
        if (payloadKey) {
          let start = new Date().getTime();
          securityParams.PayloadKey = payloadKey;
          let content_ = d.content_;
          if (content_) {
            let payload = await SecurityPayload.decrypt(content_, securityParams);
            //d.content = StringUtil.decodeURI(payload)
            d.content = payload;
          }
          let thumbnail_ = d.thumbnail_;
          if (thumbnail_) {
            let payload = await SecurityPayload.decrypt(thumbnail_, securityParams);
            d.thumbnail = payload;
          }
          let end = new Date().getTime();
          console.log('collection decrypt time:' + (end - start));
        }
      }
    }

    return data;
  }

  /**
   * 保存本地产生的文档的摘要部分，并且异步地上传到网络
   *
   * 摘要部分有两个属性需要加密处理，内容和缩略
   * @param {*} collection
   * @param {*} parent
   */
  async store(collection: any, parent: any) {
    if (!collection) {
      return;
    }
    let state = collection.state;
    let content = collection.content;
    let thumbnail = collection.thumbnail;
    let payloadKey = collection.payloadKey;
    let now = new Date().getTime();
    if (EntityState.New === state) {
      if (!collection.createDate) {
        collection.createDate = now;
      }
      if (!collection.updateDate) {
        collection.updateDate = now;
      }
    } else if (EntityState.Modified === state) {
      if (collection.versionFlag !== 'sync') {
        collection.updateDate = now;
      }
    }
    // put content into attach
    if (collection.attachs && collection.attachs.length > 0) {
      collection.attachs[0].content = content;
      collection.attachs[0].state = state;
    } else {
      collection.attachs = [{
        content: content,
        state: state
      }];
    }
    let ignore = ['attachs', 'content'];
    //let start = new Date().getTime()
    await this.save(collection, ignore, parent);
    //let end = new Date().getTime()
    //console.log('collection save run time:' + (end - start))
    //await this.storeAttach(collection)
    delete collection['content_'];
    delete collection['thumbnail_'];
  }

  /**
   * 保存本地产生的文档的附件部分，并且异步地上传到网络
   *
   * 附件部分有两个属性需要加密处理，缩略（可以没有）和附件内容
   * @param {*} collection
   */
  async storeAttach(collection: any) {
    if (collection._id && collection.attachs) {
      let securityParams: any = {};
      securityParams.PayloadKey = collection.payloadKey;
      securityParams.NeedCompress = true;
      securityParams.NeedEncrypt = true;
      for (let key in collection.attachs) {
        let attach = collection.attachs[key];
        if (EntityState.Deleted !== collection.state) {
          attach.collectionId = collection._id;
          attach.ownerPeerId = myself.myselfPeerClient.peerId;
          attach.createDate = collection.updateDate;
          if (myself.myselfPeerClient.localDataCryptoSwitch === true) {
            if (attach.content) {
              let result = await SecurityPayload.encrypt(attach.content, securityParams);
              if (result) {
                attach.securityContext = collection.SecurityContext;
                attach.payloadKey = result.PayloadKey;
                attach.needCompress = result.NeedCompress;
                attach.content_ = result.TransportPayload;
                attach.payloadHash = result.PayloadHash;
              }
            }
          }
        }
      }
      let ignore: string[] = [];
      if (myself.myselfPeerClient.localDataCryptoSwitch === true) {
        ignore = ['content'];
      }
      //let start = new Date().getTime()
      await collectionAttachService.save(collection.attachs, ignore, null);
      //let end = new Date().getTime()
      //console.log('collection attachs save run time:' + (end - start))
      for (let attach of collection.attachs) {
        delete attach['content_'];
      }
    }
  }

  /**
   * 删除
   */
  async remove(collection: any, parent: any) {
    let state = collection.state;
    if (state === EntityState.New) {
      if (parent) {
        parent.splice(parent.indexOf(collection), 1);
      }
    } else {
      collection['state'] = EntityState.Deleted;
      let attachs = collection['attachs'];
      if (attachs && attachs.length > 0) {
        for (let attach of attachs) {
          attach['state'] = EntityState.Deleted;
        }
      }
      await this.store(collection, parent);
      // put content into attach
      await this.storeAttach(collection);
    }
  }

}

export let collectionService = new CollectionService("chat_collection",
  ['ownerPeerId', 'updateDate', 'collectionType'], []);


export class CollectionAttach extends BaseEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public collectionId: string;
  public mimeType: string;
  public content: string;
  public size: string;
  public thumbnail: string;
}

export class CollectionAttachService extends BaseService {
  async load(condi: any, from: number, limit: number) {
    let data = await this.seek(condi, [{createDate: 'desc'}], null, from, limit);
    if (data && data.length > 0) {
      let payloadKey = condi.payloadKey;
      if (payloadKey) {
        let securityParams: any = {};
        securityParams.PayloadKey = payloadKey;
        securityParams.NeedCompress = true;
        securityParams.NeedEncrypt = true;
        for (let d of data) {
          let content_ = d.content_;
          if (content_) {
            let payload = await SecurityPayload.decrypt(content_, securityParams);
            //d.content = StringUtil.decodeURI(payload)
            d.content = payload;
          }
        }
      }
    }

    return data;
  }
}

export let collectionAttachService = new CollectionAttachService("chat_collectionAttach",
  ['createDate', 'collectionId'], []);

export class CollectionTag extends BaseEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public collectionId: string;
  public tag: string;
  public pyTag: string;
}

export class CollectionTagService extends BaseService {
  async loadTags(): Promise<string[]> {
    let data = await this.seek({ownerPeerId: myself.myselfPeerClient.peerId}, [{pyTag: 'asc'}]);
    if (data && data.length > 0) {
      let arr: string[] = [];
      for (let ctc of data) {
        arr.push(ctc.tag);
      }
      let uniqueArr = Array.from(new Set(arr));
      return uniqueArr;
    }
    return [];
  }
}

export let collectionTagService = new CollectionTagService("chat_collectionTag",
  ['ownerPeerId', 'createDate', 'tag', 'pyTag', 'collectionId'], []);

export class BlockLog extends BaseEntity {
  public blockId: string;
  public businessNumber: string;
}

export class BlockLogService extends BaseService {
}

export let blockLogService = new BlockLogService("chat_blockLog",
  ['businessNumber'], []);

