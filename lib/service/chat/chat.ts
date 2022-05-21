/**
 * 聊天的定义
 */
import {BaseService, EntityStatus, BaseEntity, StatusEntity} from "@/libs/datastore/base";
import {CollaUtil} from "@/libs/tool/util";
import {myself} from '@/libs/p2p/dht/myselfpeer';
import {SecurityPayload} from '@/libs/p2p/payload';
import {BlockType} from '@/libs/p2p/chain/datablock';
import {logService} from '@/libs/biz/log';
import {collectionUtil} from '@/libs/chat/collection-util';
import {EntityState} from "@/libs/datastore/datastore";

let period = 300; //5m

export enum ChatDataType {
  'MESSAGE',
  'RECEIVE',
  'ATTACH',
  'CHAT',
  'MERGEMESSAGE'
}

export let ChatContentType = {
  'ALL': 'All', // 根据场景包含类型不同，如非系统类型、可搜索类型等
  'IMAGE': 'Image',
  'TEXT': 'Text',
  'FILE': 'File',
  'AUDIO': 'Audio',
  'VIDEO': 'Video',
  'CARD': 'Card',
  'NOTE': 'Note',
  'CHANNEL': 'Channel',
  'ARTICLE': 'Article',
  'CHAT': 'Chat',
  'LINK': 'Link',
  'VOICE': 'Voice',
  'POSITION': 'Position',
  'AUDIO_INVITATION': 'AUDIO_INVITATION',
  'AUDIO_HISTORY': 'AUDIO_HISTORY',
  'VIDEO_HISTORY': 'VIDEO_HISTORY',
  'VIDEO_INVITATION': 'VIDEO_INVITATION',
  'CALL_JOIN_REQUEST': 'CALL_JOIN_REQUEST',
  'EVENT': 'EVENT',
  'TIME': 'TIME',
  'MEDIA_REJECT': 'MEDIA_REJECT',
  'MEDIA_CLOSE': 'MEDIA_CLOSE',
  'MEDIA_BUSY': 'MEDIA_BUSY'
};

// 消息类型（messageType）
export let P2pChatMessageType = {
  'ADD_LINKMAN': 'ADD_LINKMAN', // 新增联系人请求
  'ADD_LINKMAN_REPLY': 'ADD_LINKMAN_REPLY', // 新增联系人请求的回复
  'SYNC_LINKMAN_INFO': 'SYNC_LINKMAN_INFO', // 联系人基本信息同步
  'DROP_LINKMAN': 'DROP_LINKMAN', // 从好友中删除
  'DROP_LINKMAN_RECEIPT': 'DROP_LINKMAN_RECEIPT', // 删除好友通知回复
  'BLACK_LINKMAN': 'BLACK_LINKMAN', // 加入黑名单
  'BLACK_LINKMAN_RECEIPT': 'BLACK_LINKMAN_RECEIPT', // 加入黑名单通知回复
  'UNBLACK_LINKMAN': 'UNBLACK_LINKMAN', // 从黑名单中移除
  'UNBLACK_LINKMAN_RECEIPT': 'UNBLACK_LINKMAN_RECEIPT', // 移除黑名单通知回复
  // 联系人请求
  'ADD_GROUPCHAT': 'ADD_GROUPCHAT', // 新增群聊请求
  'ADD_GROUPCHAT_RECEIPT': 'ADD_GROUPCHAT_RECEIPT', // 新增群聊请求接收回复
  'DISBAND_GROUPCHAT': 'DISBAND_GROUPCHAT', // 解散群聊请求
  'DISBAND_GROUPCHAT_RECEIPT': 'DISBAND_GROUPCHAT_RECEIPT', // 解散群聊请求接收回复
  'MODIFY_GROUPCHAT': 'MODIFY_GROUPCHAT', // 修改群聊请求
  'MODIFY_GROUPCHAT_RECEIPT': 'MODIFY_GROUPCHAT_RECEIPT', // 修改群聊请求接收回复
  'MODIFY_GROUPCHAT_OWNER': 'MODIFY_GROUPCHAT_OWNER', // 修改群主请求
  'MODIFY_GROUPCHAT_OWNER_RECEIPT': 'MODIFY_GROUPCHAT_OWNER_RECEIPT', // 修改群主请求接收回复
  'ADD_GROUPCHAT_MEMBER': 'ADD_GROUPCHAT_MEMBER', // 新增群聊成员请求
  'ADD_GROUPCHAT_MEMBER_RECEIPT': 'ADD_GROUPCHAT_MEMBER_RECEIPT', // 新增群聊成员请求接收回复
  'REMOVE_GROUPCHAT_MEMBER': 'REMOVE_GROUPCHAT_MEMBER', // 删除群聊成员请求
  'REMOVE_GROUPCHAT_MEMBER_RECEIPT': 'REMOVE_GROUPCHAT_MEMBER_RECEIPT', // 删除群聊成员请求接收回复
  // 聊天
  'CHAT_SYS': 'CHAT_SYS', // 系统预定义聊天消息，如群聊动态通知
  'CHAT_LINKMAN': 'CHAT_LINKMAN', // 联系人发送聊天消息
  'CHAT_RECEIVE_RECEIPT': 'CHAT_RECEIVE_RECEIPT', // 接收回复
  'CALL_CLOSE': 'CALL_CLOSE',
  'CALL_REQUEST': 'CALL_REQUEST', // 通话请求
  'RECALL': 'RECALL',
  'GROUP_FILE': 'GROUP_FILE'
};
export let ChatMessageStatus = {
  'NORMAL': 'NORMAL',
  'RECALL': 'RECALL',
  'DELETE': 'DELETE',
};
export let SubjectType = {
  'CHAT': 'CHAT',
  'LINKMAN_REQUEST': 'LINKMAN_REQUEST',
  'GROUP_CHAT': 'GROUP_CHAT',
};


// 消息（单聊/群聊）
export class ChatMessage extends StatusEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public subjectType: string; // 包括：Chat（单聊）, GroupChat（群聊）
  public subjectId: string; // 主题的唯一id标识（单聊对应linkman-peerId，群聊对应group-groupId）
  public messageId: string; // 消息的唯一id标识
  public messageType: string; // 消息类型（对应channel消息类型）
  public senderPeerId: string; // 消息发送方（作者）peerId
  public receiveTime: Date; // 接收时间
  public actualReceiveTime: Date; // 实际接收时间 1.发送端发送消息时receiveTime=createDate，actualReceiveTime=null；2.根据actualReceiveTime是否为null判断是否需要重发，收到接受回执时更新actualReceiveTime；3.聊天区按receiveTime排序，查找聊天内容按createDate排序
  public readTime: Date; // 阅读时间
  public title: string; // 消息标题
  public thumbBody: string; // 预览内容（适用需预览的content，如笔记、转发聊天）
  public thumbnail: string; // 预览缩略图（base64图片，适用需预览的content，如笔记、联系人名片）
  public content: string; // 消息内容
  public contentType: string;
  public destroyTime: string;

  public payloadHash: string;
  public signature: string;
  public primaryPeerId: string;
  /**
   * primary peer的publicKey
   */
  public primaryPublicKey: string;
  public primaryAddress: string;
  public payloadKey: string;
  public ephemeralPublicKey: string;
  // 其它: 加密相关字段，自动销毁相关字段
}

export class ChatMessageService extends BaseService {
  async load(condi: any, sort: any, from: number, limit: number, notDecrypt: boolean = false): Promise<any> {
    let condition = this.buildCondition(condi);
    let qs = condition['$and'];
    if (from) {
      qs.push({receiveTime: {$lt: from}});
    } else {
      //qs.push({ _id: { $lt: null } })
    }
    if (qs.length > 0) {
      condition['$and'] = qs;
    }
    let data: any = await this.find(condition, sort, null, null, limit);
    if (notDecrypt) {
      return data;
    } else {
      if (myself.myselfPeerClient.localDataCryptoSwitch) {
        if (data && data.length > 0) {
          let dataMap = new Map();
          let encryptPayloadMap = new Map();
          for (let d of data) {
            let _id = d._id;
            dataMap.set(_id, d);
            let payloadKey = d.payloadKey;
            let encryptPayloads = encryptPayloadMap.get(payloadKey);
            if (!encryptPayloadMap.has(payloadKey)) {
              encryptPayloads = [];
              encryptPayloadMap.set(payloadKey, encryptPayloads);
            }
            let encryptPayload = null;
            if (d.content) {
              encryptPayload =
                {
                  _id: d._id,
                  type: 'content',
                  needCompress: d.needCompress,
                  encryptData: d.content,
                  signature: d.signature,
                  payloadKey: payloadKey,
                  ephemeralPublicKey: d.ephemeralPublicKey
                };
              encryptPayloads.push(encryptPayload);
            }
            if (d.thumbnail) {
              encryptPayload =
                {
                  _id: d._id,
                  type: 'thumbnail',
                  needCompress: false,
                  encryptData: d.thumbnail,
                  payloadKey: payloadKey,
                  ephemeralPublicKey: d.ephemeralPublicKey
                };
              encryptPayloads.push(encryptPayload);
            }
          }
          let securityParams: any = {};
          securityParams.NeedCompress = true;
          securityParams.NeedEncrypt = true;
          for (let payloadKey of encryptPayloadMap.keys()) {
            let encryptPayloads = encryptPayloadMap.get(payloadKey);
            securityParams.PayloadKey = payloadKey;
            let payloads = await SecurityPayload.decrypt(encryptPayloads, securityParams);
            if (payloads && payloads.length > 0) {
              for (let payload of payloads) {
                let _id = payload._id;
                let type = payload.type;
                if (dataMap.has(_id)) {
                  let d = dataMap.get(_id);
                  if (type === 'content') {
                    d.content = payload.data;
                  } else {
                    if (type === 'thumbnail') {
                      d.thumbnail = payload.data;
                    }
                  }
                }
              }
            }
          }
        }
      }
      return data;
    }
  }

  async store(entities: any[], parent: any = undefined) {
    if (entities.length <= 0) {
      return;
    }
    if (myself.myselfPeerClient.localDataCryptoSwitch) {
      let securityParams: any = {};
      securityParams.NeedCompress = true;
      securityParams.NeedEncrypt = true;
      for (let current of entities) {
        let state = current.state;
        if (EntityState.Deleted === state) {
          continue;
        }
        securityParams.PayloadKey = current.payloadKey;
        let content = current.content;
        if (!content) {
          continue;
        }
        let result = await SecurityPayload.encrypt(content, securityParams);
        if (!result) {
          continue;
        }
        current.payloadKey = result.PayloadKey;
        current.needCompress = result.NeedCompress;
        current.content_ = result.TransportPayload;
        current.payloadHash = result.PayloadHash;
      }
    }
    await this.save(entities, ['mediaProperty', 'mergeMessages'], parent);
  }
}

export let chatMessageService = new ChatMessageService("chat_message",
  ['ownerPeerId', 'subjectId', 'createDate', 'receiveTime', 'actualReceiveTime', 'blockId', 'messageType', 'attachBlockId'],
  ['title', 'content']);


export class MergeMessage extends BaseEntity {

}

export class MergeMessageService extends BaseService {
  async load(condi: any, sort: any, from: number, limit: number) {
    condi['ownerPeerId'] = myself.myselfPeerClient.peerId;
    let data = await this.seek(condi, sort, null, from, limit);
    return data;
  }
}

export let mergeMessageService = new MergeMessageService("chat_mergemessage", ['ownerPeerId', 'mergeMessageId', 'createDate'], []);

// 附件（单聊/群聊/频道/收藏）
export class ChatAttach extends BaseEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public messageId: string; // 消息的唯一id标识
  public subjectId: string; // 外键（对应subject-subjectId）
  public content: string; // 消息内容（基于mime+自定义标识区分内容类型，如：application/audio/image/message/text/video/x-word, contact联系人名片, groupChat群聊, channel频道）

}

export class ChatAttachService extends BaseService {
  async store(entity: any) {
    let attachs = entity.attachs;
    if (myself.myselfPeerClient.localDataCryptoSwitch) {
      let securityParams: any = {};
      securityParams.NeedCompress = true;
      securityParams.NeedEncrypt = true;
      for (let key in attachs) {
        let attach = attachs[key];
        if (EntityState.Deleted === entity.state) {
          attach.state = EntityState.Deleted;
          continue;
        }
        if (attach.content) {
          securityParams.PayloadKey = attach.payloadKey;
          let payload = attach.content;
          let result = await SecurityPayload.encrypt(payload, securityParams);
          if (result) {
            attach.securityContext = entity.SecurityContext;
            attach.payloadKey = result.PayloadKey;
            attach.needCompress = result.NeedCompress;
            attach.content_ = result.TransportPayload;
            attach.payloadHash = result.PayloadHash;
          }
        }
      }
      await this.save(attachs, ['content'], entity.attachs);
      for (let attach of entity.attachs) {
        delete attach['content_'];
      }
    } else {
      await this.save(attachs, [], entity.attachs);
    }
  }

  async load(attachBlockId: any, from: number) {
    let condi = {attachBlockId: attachBlockId, ownerPeerId: myself.myselfPeerClient.peerId};
    let data = await this.seek(condi, null, null, null, null);
    if (data && data.length > 0) {
      let securityParams: any = {};
      securityParams.NeedCompress = true;
      securityParams.NeedEncrypt = true;
      for (let d of data) {
        let payloadKey = d.payloadKey;
        if (payloadKey) {
          securityParams.PayloadKey = payloadKey;
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

export let chatAttachService = new ChatAttachService("chat_attach", ['ownerPeerId', 'subjectId', 'createDate', 'messageId'], []);


// 发送接收记录（群聊联系人请求/群聊/频道）
export class Receive extends BaseEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public subjectType: string; // 外键（对应message-subjectType、对群聊联系人请求为LinkmanRequest）
  public subjectId: string; // 外键（对应message-subjectId、对群聊联系人请求为空）
  public messageType: string; // 外键（对应message-messageType、linkmanRequest-requestType）
  public messageId: string; // 外键（对应message-messageId、linkmanRequest-_id）
  public receiverPeerId: string; // 消息接收方peerId
  public receiveTime: Date; // 接收时间

  // 其它: 如：自动销毁相关字段...
}

export class ReceiveService extends BaseService {
}

export let receiveService = new ReceiveService("chat_receive", ['ownerPeerId', 'subjectId', 'createDate', 'subjectType', 'receiverPeerId', 'blockId'], []);

export class Chat extends BaseEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public subjectType: string; // 包括：Chat（单聊）, GroupChat（群聊）
  public subjectId: string; // 主题的唯一id标识（单聊对应linkman-peerId，群聊对应group-groupId）
  public content: string;
}

export class ChatService extends BaseService {
  async load(condi: any, sort: any, from: number, limit: number, includeMessage: boolean = true) {
    let data: any = await this.seek(condi, sort, null, from, limit);
    if (includeMessage) {
      if (data && data.length > 0) {
        for (let chat of data) {
          let messages = [];
          messages = await chatMessageService.load({
            ownerPeerId: myself.myselfPeerClient.peerId,
            subjectId: chat.subjectId
          }, [{_id: 'desc'}], null, 10);
          CollaUtil.sortByKey(messages, 'receiveTime', 'asc');
          chat.messages = messages;
        }
      }
    }
    return data;
  }


  async store(entities: any[], parent: any) {
    if (!entities) {
      return;
    }
    await this.save(entities, ['messages', 'stream', 'streamMap', 'audio', 'focusedMessage', 'tempText'], parent);
  }


  calcTime(current: any, messages: any[]) {
    let currentTime = current.createDate;
    let preTime = currentTime.setTime(new Date().getTime() - 1000 * period);
    let isNeedInsert = true;
    if (messages && messages.length > 0) {
      for (let i = messages.length; i > -1; i--) {
        let _message = messages[i];
        if (_message.messageType === P2pChatMessageType.CHAT_SYS && _message.contentType === ChatContentType.TIME) {
          let _time = _message.createDate;
          if (_time <= preTime) {
            isNeedInsert = false;
          }
        }
      }
    }
    if (isNeedInsert) {
      let message = {
        messageType: P2pChatMessageType.CHAT_SYS,
        contentType: ChatContentType.TIME,
        content: currentTime
      };
    }
  }
}


export let chatService = new ChatService("chat_chat", ['ownerPeerId', 'subjectId', 'createDate', 'updateTime'], []);


export class ChatBlockService {
  async store(current: any, _peers: any) {
    let _that = this;
    let blockType = BlockType.ChatAttach;
    let expireDate = new Date().getTime() + 1000 * 3600 * 24 * 10; // 10 days
    if (current.messageType === P2pChatMessageType.GROUP_FILE) {
      blockType = BlockType.GroupFile;
      expireDate = new Date().getTime() + 1000 * 3600 * 24 * 365 * 100; // 100 years
    }
    let blockResult = await collectionUtil.saveBlock(current, true, blockType, _peers, expireDate);
    let result = true;
    if (blockResult) {
      current.state = EntityState.New;
      await chatAttachService.store(current);
    } else {
      result = false;
    }
    return result;
  }

}


export let chatBlockService = new ChatBlockService();
