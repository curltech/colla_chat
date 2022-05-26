import '../base.dart';

enum RequestType {
  ADD_LINKMAN,
  DROP_LINKMAN,
  BLACK_LINKMAN,
  UNBLACK_LINKMAN,
  ADD_GROUPCHAT,
  DISBAND_GROUPCHAT,
  MODIFY_GROUPCHAT,
  MODIFY_GROUPCHAT_OWNER,
  ADD_GROUPCHAT_MEMBER,
  REMOVE_GROUPCHAT_MEMBER
}

enum RequestStatus { SENT, RECEIVED, ACCEPTED, EXPIRED, IGNORED }

enum LinkmanStatus {
  BLACKED, // 已加入黑名单
  EFFECTIVE, // 已成为好友
  REQUESTED // 已发送好友请求
}

enum GroupStatus {
  EFFECTIVE, // 有效
  DISBANDED // 已解散
}

enum MemberType { MEMBER, OWNER }

enum ActiveStatus { DOWN, UP }

// 联系人
class Linkman extends StatusEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? peerId; // peerId
  String? name; // 用户名
  String? pyName; // 用户名拼音
  String? mobile; // 手机号
  String? avatar; // 头像
  String? publicKey; // 公钥
  String? givenName; // 备注名
  String? pyGivenName; // 备注名拼音
  String? sourceType; // 来源，包括：Search&Add（搜索添加）, AcceptRequest（接受请求）…
  String? lastConnectTime; // 最近连接时间
  bool? locked; // 是否锁定，包括：true（锁定）, false（未锁定）
  bool? notAlert; // 消息免打扰，包括：true（提醒）, false（免打扰）
  bool? top; // 是否置顶，包括：true（置顶）, false（不置顶）
  bool? blackedMe; // true-对方已将你加入黑名单
  bool? droppedMe; // true-对方已将你从好友中删除

  // 非持久化属性
  //activeStatus: 活动状态，包括：Up（连接）, Down（未连接）
  //downloadSwitch: 自动下载文件开关
  //udpSwitch: 启用UDP开关
  //groupChats: 关联群聊列表
  //tag: 标签
  //pyTag: 标签拼音
  String? activeStatus;
  bool? recallTimeLimit;
  bool? recallAlert;
  bool? myselfRecallTimeLimit;
  bool? myselfRecallAlert;
}

// 联系人标签
class LinkmanTag extends BaseEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? name; // 标签名称
}

// 联系人标签关系
class LinkmanTagLinkman extends BaseEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? tagId; // 标签主键_id
  String? linkmanPeerId; // 联系人peerId
}

// 联系人请求
class LinkmanRequest extends StatusEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? senderPeerId; // 发送者peerId
  String? name; // 用户名
  String? mobile; // 手机号
  String? avatar; // 头像
  String? publicKey; // 公钥
  String? receiverPeerId; // 接收者peerId
  String? requestType; // 请求类型
  String? receiveTime; // 接收时间
  // 状态，包括：Sent/Received/Accepted/Expired/Ignored（已发送/已接收/已同意/已过期/已忽略）
  String? message; // 邀请信息
  String? groupId; // 群Id
  String? groupCreateDate; // 群创建时间
  String? groupName; // 群名称
  String? groupDescription; // 群公告
  String? myAlias; // 发送人在本群的昵称
  String? data; // 消息数据（群成员列表）
  String? blackedMe;
}

// 组（群聊/频道）
class Group extends StatusEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? groupId; // 组的唯一id标识
  String? groupCategory; // 组类别，包括：Chat（群聊）, Channel（频道）
  String?
      groupType; // 组类型，包括：Private（私有，群聊群主才能添加成员，频道外部不可见）, Public（公有，群聊非群主也能添加成员，频道外部可见）
  String? name; // 组名称
  String? description; // 组描述
  String? givenName; // 备注名
  String? pyGivenName; // 备注名拼音
  String? tag; // 搜索标签
  String? pyName; // 组名称拼音
  String? pyDescription; // 组描述拼音
  String? pyTag; // 标签拼音
  bool? locked; // 是否锁定（群聊不使用，频道使用），包括：true（锁定）, false（未锁定）
  bool? alert; // 是否提醒，包括：true（提醒）, false（免打扰）
  bool? top; // 是否置顶，包括：true（置顶）, false（不置顶）
  String? myAlias; // 我在本群的昵称

//this.avatar = null // 头像（保留，适用于频道）
//this.shareLink = null // 分享链接（保留，适用于频道）

// 非持久化属性（群聊groupChat）
//activeStatus: 活动状态（除自己以外至少一个成员activeStatus为Up，则为Up，否则为Down），包括：Up（有连接）, Down（无连接）
//groupOwnerPeerId: 群主peerId
}

// 组成员
class GroupMember extends StatusEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? groupId; // 外键（对应group-groupId）
  String? memberPeerId; // 外键（对应linkman-peerId）
  String? memberAlias; // 成员别名
  String?
      memberType; // 成员类型，包括：Owner（创建者/群主，默认管理员）, Member（一般成员）,…可能的扩充：Admin（管理员）, Subscriber（订阅者）
}

class Contact extends StatusEntity {
  String? peerId;
  String? name;
  String? formattedName;
  late String mobile;
  String? trustLevel;
  String? publicKey;
  String? avatar;
  String? pyName;
  String? givenName;
  String? pyGivenName;
  bool? locked;
  bool? isLinkman;
}
