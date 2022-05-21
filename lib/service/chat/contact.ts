/**
 * 联系人的定义
 */
import {BaseService, BaseEntity, StatusEntity} from "@/libs/datastore/base";
import {myself} from '@/libs/p2p/dht/myselfpeer';
import {phoneContactComponent} from '@/libs/tool/cordova';
import pinyinUtil from '@/libs/tool/pinyin';
import {peerClientService} from "@/libs/p2p/dht/peerclient";
import {MobileNumberUtil} from "@/libs/tool/util";

export enum RequestType {
  'ADD_LINKMAN',
  'DROP_LINKMAN',
  'BLACK_LINKMAN',
  'UNBLACK_LINKMAN',
  'ADD_GROUPCHAT',
  'DISBAND_GROUPCHAT',
  'MODIFY_GROUPCHAT',
  'MODIFY_GROUPCHAT_OWNER',
  'ADD_GROUPCHAT_MEMBER',
  'REMOVE_GROUPCHAT_MEMBER'
}

export enum RequestStatus {
  'SENT',
  'RECEIVED',
  'ACCEPTED',
  'EXPIRED',
  'IGNORED'
}

export enum LinkmanStatus {
  'BLACKED', // 已加入黑名单
  'EFFECTIVE', // 已成为好友
  'REQUESTED' // 已发送好友请求
}

export enum GroupStatus {
  'EFFECTIVE', // 有效
  'DISBANDED' // 已解散
}

export enum MemberType {
  'MEMBER',
  'OWNER'
}

export enum ActiveStatus {
  'DOWN',
  'UP'
}

// 联系人
export class Linkman extends StatusEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public peerId: string; // peerId
  public name: string; // 用户名
  public pyName: string; // 用户名拼音
  public mobile: string; // 手机号
  public avatar: string; // 头像
  public publicKey: string; // 公钥
  public givenName: string; // 备注名
  public pyGivenName: string; // 备注名拼音
  public sourceType: string; // 来源，包括：Search&Add（搜索添加）, AcceptRequest（接受请求）…
  public lastConnectTime: string; // 最近连接时间
  public locked: boolean; // 是否锁定，包括：true（锁定）, false（未锁定）
  public notAlert: boolean; // 消息免打扰，包括：true（提醒）, false（免打扰）
  public top: boolean; // 是否置顶，包括：true（置顶）, false（不置顶）
  public blackedMe: boolean; // true-对方已将你加入黑名单
  public droppedMe: boolean; // true-对方已将你从好友中删除

  // 非持久化属性
  //activeStatus: 活动状态，包括：Up（连接）, Down（未连接）
  //downloadSwitch: 自动下载文件开关
  //udpSwitch: 启用UDP开关
  //groupChats: 关联群聊列表
  //tag: 标签
  //pyTag: 标签拼音
  public activeStatus: string;
  public recallTimeLimit: boolean;
  public recallAlert: boolean;
  public myselfRecallTimeLimit: boolean;
  public myselfRecallAlert: boolean;
}

export class LinkmanService extends BaseService {

}

export let linkmanService = new LinkmanService("chat_linkman",
  ['ownerPeerId', 'peerId', 'mobile', 'collectionType'],
  ['givenName', 'name', 'mobile']);

export let linkmans: Linkman[] = [];

// 联系人标签
export class LinkmanTag extends BaseEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public name: string; // 标签名称
}

export class LinkmanTagService extends BaseService {

}

export let linkmanTagService = new LinkmanTagService("chat_linkmanTag",
  ['ownerPeerId', 'createDate', 'name'],
  []);

// 联系人标签关系
export class LinkmanTagLinkman extends BaseEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public tagId: string; // 标签主键_id
  public linkmanPeerId: string; // 联系人peerId
}

export class LinkmanTagLinkmanService extends BaseService {

}

export let linkmanTagLinkmanService = new LinkmanTagLinkmanService("chat_linkmanTagLinkman",
  ['ownerPeerId', 'createDate', 'tagId', 'linkmanPeerId'],
  []);

// 联系人请求
export class LinkmanRequest extends StatusEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public senderPeerId: string; // 发送者peerId
  public name: string; // 用户名
  public mobile: string; // 手机号
  public avatar: string; // 头像
  public publicKey: string; // 公钥
  public receiverPeerId: string; // 接收者peerId
  public requestType: string; // 请求类型
  public receiveTime: string; // 接收时间
  // 状态，包括：Sent/Received/Accepted/Expired/Ignored（已发送/已接收/已同意/已过期/已忽略）
  public message: string; // 邀请信息
  public groupId: string; // 群Id
  public groupCreateDate: string; // 群创建时间
  public groupName: string; // 群名称
  public groupDescription: string; // 群公告
  public myAlias: string; // 发送人在本群的昵称
  public data: string; // 消息数据（群成员列表）
  public blackedMe: string;
}

export class LinkmanRequestService extends BaseService {

}

export let linkmanRequestService = new LinkmanRequestService("chat_linkmanRequest",
  ['ownerPeerId', 'createDate', 'receiverPeerId', 'senderPeerId', 'status'],
  []);

// 组（群聊/频道）
export class Group extends StatusEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public groupId: string; // 组的唯一id标识
  public groupCategory: string; // 组类别，包括：Chat（群聊）, Channel（频道）
  public groupType: string; // 组类型，包括：Private（私有，群聊群主才能添加成员，频道外部不可见）, Public（公有，群聊非群主也能添加成员，频道外部可见）
  public name: string; // 组名称
  public description: string; // 组描述
  public givenName: string; // 备注名
  public pyGivenName: string; // 备注名拼音
  public tag: string; // 搜索标签
  public pyName: string; // 组名称拼音
  public pyDescription: string; // 组描述拼音
  public pyTag: string; // 标签拼音
  public locked: boolean; // 是否锁定（群聊不使用，频道使用），包括：true（锁定）, false（未锁定）
  public alert: boolean; // 是否提醒，包括：true（提醒）, false（免打扰）
  public top: boolean; // 是否置顶，包括：true（置顶）, false（不置顶）
  public myAlias: string; // 我在本群的昵称

  //this.avatar = null // 头像（保留，适用于频道）
  //this.shareLink = null // 分享链接（保留，适用于频道）

  // 非持久化属性（群聊groupChat）
  //activeStatus: 活动状态（除自己以外至少一个成员activeStatus为Up，则为Up，否则为Down），包括：Up（有连接）, Down（无连接）
  //groupOwnerPeerId: 群主peerId
}

export class GroupService extends BaseService {

}

export let groupService = new GroupService("chat_group",
  ['ownerPeerId', 'createDate', 'groupId', 'groupCategory', 'groupType'],
  ['givenName', 'name', 'description'/*, 'tag'*/]);

// 组成员
export class GroupMember extends StatusEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public groupId: string; // 外键（对应group-groupId）
  public memberPeerId: string; // 外键（对应linkman-peerId）
  public memberAlias: string; // 成员别名
  public memberType: string; // 成员类型，包括：Owner（创建者/群主，默认管理员）, Member（一般成员）,…可能的扩充：Admin（管理员）, Subscriber（订阅者）
}

export class GroupMemberService extends BaseService {

}

export let groupMemberService = new GroupMemberService("chat_groupmember",
  ['ownerPeerId', 'createDate', 'groupId', 'memberPeerId', 'memberType'],
  []);

export class Contact extends StatusEntity {
  public peerId: string;
  public name: string;
  public formattedName: string;
  public mobile: string;
  public trustLevel: string;
  public publicKey: string;
  public avatar: string;
  public pyName: string;
  public givenName: string;
  public pyGivenName: string;
  public locked: boolean;
  public isLinkman: boolean;
}

export class ContactService extends BaseService {
  formatMobile(mobile: string): string {
    let countryCode = null;
    try {
      countryCode = MobileNumberUtil.parse(mobile).getCountryCode();
    } catch (e) {
      console.log(e);
    }
    if (!countryCode) {
      let myMobileCountryCode = MobileNumberUtil.parse(myself.myselfPeerClient.mobile).getCountryCode();
      console.log('myMobileCountryCode:' + myMobileCountryCode);
      if (myMobileCountryCode) {
        countryCode = myMobileCountryCode;
      }
    }
    if (countryCode) {
      let isPhoneNumberValid = false;
      try {
        isPhoneNumberValid = MobileNumberUtil.isPhoneNumberValid(mobile, MobileNumberUtil.getRegionCodeForCountryCode(countryCode));
      } catch (e) {
        console.log(e);
      }
      if (isPhoneNumberValid) {
        mobile = MobileNumberUtil.formatE164(mobile, MobileNumberUtil.getRegionCodeForCountryCode(countryCode));
        console.log('formatE164:' + mobile);
      }
    }

    return mobile;
  }

  /**
   * 获取手机电话本的数据填充peerContacts数组，校验是否好友，是否存在peerId
   * @param {*} peerContacts
   * @param {*} linkmans
   */
  fillPeerContact(peerContacts: any[], linkmans: any[]) {
    let filter = '';
    let fields = [navigator.contacts.fieldType.displayName, navigator.contacts.fieldType.name, navigator.contacts.fieldType.phoneNumbers];
    let options = {
      multiple: true,
      hasPhoneNumber: true
    };

    phoneContactComponent.find(filter, fields, options).then(async (contacts: any[]) => {
      // 把通讯录的数据规整化，包含手机号和名称，然后根据手机号建立索引
      let peerContactMap = new Map();
      if (contacts && contacts.length > 0) {
        for (let contact of contacts) {
          let peerContact: any = {};
          if (contact.name.formatted) {
            peerContact.formattedName = contact.name.formatted.trim();
            peerContact.pyFormattedName = pinyinUtil.getPinyin(peerContact.formattedName);
          }
          if (contact.phoneNumbers && contact.phoneNumbers.length > 0) {
            for (let phoneNumber of contact.phoneNumbers) {
              if (phoneNumber.type === 'mobile') {
                peerContact.mobile = this.formatMobile(phoneNumber.value);
                break;
              }
            }
            if (!peerContact.mobile) {
              peerContact.mobile = this.formatMobile(contact.phoneNumbers[0].value);
            }
          }
          peerContactMap.set(peerContact.mobile, peerContact);
        }
      }
      // 遍历本地库的记录，根据手机号检查索引
      let pContacts = await this.seek({});
      if (pContacts && pContacts.length > 0) {
        for (let pContact of pContacts) {
          // 如果通讯录中存在，将本地匹配记录放入结果集
          let peerContact = peerContactMap.get(pContact.mobile);
          if (peerContact) {
            peerContacts.push(pContact);
            peerContactMap.delete(pContact.mobile);
          } else { // 如果通讯录不存在，则本地库删除
            this.delete(pContact);
          }
        }
      }
      // 通讯录中剩余的记录，新增的记录将被检查好友记录和服务器记录，然后插入本地库并加入结果集
      let leftPeerContacts = peerContactMap.values();
      if (leftPeerContacts) {
        for (let leftPeerContact of leftPeerContacts) {
          let pc = this.updateByLinkman(leftPeerContact, linkmans);
          if (!pc) {
            pc = await this.refresh(leftPeerContact);
          }
          if (pc) {
            this.insert(leftPeerContact);
          }
          peerContacts.push(leftPeerContact);
        }
      }
    }).catch((err: any) => {
      console.error(err);
    });
  }

  updateByLinkman(peerContact: Contact, linkmans: Linkman[]): Contact {
    if (linkmans && linkmans.length > 0) {
      for (let linkman of linkmans) {
        if (linkman.mobile === peerContact.mobile) {
          peerContact.peerId = linkman.peerId;
          peerContact.name = linkman.name;
          peerContact.pyName = linkman.pyName;
          peerContact.givenName = linkman.givenName;
          peerContact.pyGivenName = linkman.pyGivenName;
          peerContact.locked = linkman.locked;
          peerContact.status = linkman.status;
          peerContact.publicKey = linkman.publicKey;
          peerContact.avatar = linkman.avatar;
          peerContact.isLinkman = true;

          return peerContact;
        }
      }
    }
  }

  // 从服务器端获取是否有peerClient
  async refresh(peerContact: Contact): Promise<Contact> {
    if (peerContact) {
      let mobileNumber = this.formatMobile(peerContact.mobile);
      if (mobileNumber) {
        let peerClient = await peerClientService.findPeerClient(null, null, mobileNumber, null);
        if (peerClient) {
          console.info('find peerclient:' + peerClient);
          peerContact.peerId = peerClient.peerId;
          peerContact.name = peerClient.name;
          peerContact.trustLevel = peerClient.trustLevel;
          peerContact.status = peerClient.status;
          peerContact.publicKey = peerClient.publicKey;
          peerContact.avatar = peerClient.avatar;

          return peerContact;
        }
      }
    }
  }
}

export let contactService = new ContactService("chat_contact",
  ['peerId', 'mobile', 'formattedName', 'name'],
  []);
