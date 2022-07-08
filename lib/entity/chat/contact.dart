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

enum ActiveStatus { DOWN, UP }

//当事方，联系人，群，手机联系人（潜在联系人）的共同父类
abstract class Party extends StatusEntity {
  String ownerPeerId; // 区分属主
  String peerId; // peerId,事实上的单个属主的主键
  String name; // 用户名
  String? pyName; // 用户名拼音
  String? mobile; // 手机号
  String? email; // 手机号
  String? avatar; // 头像
  String? publicKey; // 公钥
  String? peerPublicKey; // 公钥
  String? givenName; // 备注名
  String? pyGivenName; // 备注名拼音
  String? sourceType; // 来源，包括：Search&Add（搜索添加）, AcceptRequest（接受请求）…
  String? lastConnectTime; // 最近连接时间
  bool locked = false; // 是否锁定，包括：true（锁定）, false（未锁定）
  bool notAlert = false; // 消息免打扰，包括：true（提醒）, false（免打扰）
  bool top = false; // 是否置顶，包括：true（置顶）, false（不置顶）
  bool blackedMe = false; // true-对方已将你加入黑名单
  bool droppedMe = false; // true-对方已将你从好友中删除
  bool recallTimeLimit = false;
  bool recallAlert = false;
  bool myselfRecallTimeLimit = false;
  bool myselfRecallAlert = false;

  // 非持久化属性
  String? activeStatus; //: 活动状态，包括：Up（连接）, Down（未连接）
  bool downloadSwitch = true; //: 自动下载文件开关
  bool udpSwitch = false; //: 启用UDP开关
  String? groupChats; // 关联群聊列表
  String? tag; //: 标签
  String? pyTag; //: 标签拼音
  List<Tag> tags = [];

  Party(this.ownerPeerId, this.peerId, this.name) : super();

  Party.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        peerId = json['peerId'],
        name = json['name'],
        pyName = json['pyName'],
        mobile = json['mobile'],
        email = json['email'],
        avatar = json['avatar'],
        publicKey = json['publicKey'],
        peerPublicKey = json['peerPublicKey'],
        givenName = json['givenName'],
        pyGivenName = json['pyGivenName'],
        sourceType = json['sourceType'],
        lastConnectTime = json['lastConnectTime'],
        locked = json['locked'] == true || json['locked'] == 1 ? true : false,
        notAlert =
            json['notAlert'] == true || json['notAlert'] == 1 ? true : false,
        top = json['top'] == true || json['top'] == 1 ? true : false,
        blackedMe =
            json['blackedMe'] == true || json['blackedMe'] == 1 ? true : false,
        droppedMe =
            json['droppedMe'] == true || json['droppedMe'] == 1 ? true : false,
        activeStatus = json['activeStatus'],
        recallTimeLimit =
            json['recallTimeLimit'] == true || json['recallTimeLimit'] == 1
                ? true
                : false,
        recallAlert = json['recallAlert'] == true || json['recallAlert'] == 1
            ? true
            : false,
        myselfRecallTimeLimit = json['myselfRecallTimeLimit'] == true ||
                json['myselfRecallTimeLimit'] == 1
            ? true
            : false,
        myselfRecallAlert =
            json['myselfRecallAlert'] == true || json['myselfRecallAlert'] == 1
                ? true
                : false,
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'peerId': peerId,
      'name': name,
      'pyName': pyName,
      'mobile': mobile,
      'email': email,
      'avatar': avatar,
      'publicKey': publicKey,
      'peerPublicKey': peerPublicKey,
      'givenName': givenName,
      'pyGivenName': pyGivenName,
      'sourceType': sourceType,
      'lastConnectTime': lastConnectTime,
      'locked': locked,
      'notAlert': notAlert,
      'top': top,
      'blackedMe': blackedMe,
      'droppedMe': droppedMe,
      'activeStatus': activeStatus,
      'recallTimeLimit': recallTimeLimit,
      'recallAlert': recallAlert,
      'myselfRecallTimeLimit': myselfRecallTimeLimit,
      'myselfRecallAlert': myselfRecallAlert,
    });
    return json;
  }
}

// 联系人，或者叫好友，发起请求通过后才能成为联系人
class Linkman extends Party {
  Linkman(String ownerPeerId, String peerId, String name)
      : super(ownerPeerId, peerId, name);

  Linkman.fromJson(Map json) : super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({});
    return json;
  }
}

// 联系人标签
class Tag extends BaseEntity {
  String ownerPeerId; // 区分本地不同peerClient属主
  String? tag; // 标签名称
  Tag(this.ownerPeerId);

  Tag.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        tag = json['tag'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'tag': tag,
    });
    return json;
  }
}

// 联系人标签关系
class PartyTag extends BaseEntity {
  String ownerPeerId; // 区分本地不同peerClient属主
  String? tag; // 标签
  String? partyPeerId; // party peerId
  String? partyType; // party type:linkman,group,channel,contact
  PartyTag(this.ownerPeerId);

  PartyTag.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        tag = json['tag'],
        partyPeerId = json['partyPeerId'],
        partyType = json['partyType'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'tag': tag,
      'partyPeerId': partyPeerId,
      'partyType': partyType,
    });
    return json;
  }
}

// 联系人请求是消息的一种，这里记录了消息的内容字段经过标准化的数据，
// 本表的数据经过json格式序列化后成为消息表中的content字段的内容
class PartyRequest extends Party {
  String? requestType; // 请求类型，加好友，入群，订阅频道
  // 状态，包括：Sent/Received/Accepted/Expired/Ignored（已发送/已接收/已同意/已过期/已忽略）
  String? messageId; // 邀请信息
  String? targetPeerId; // 要加入的好友的peerId
  String? targetType; // 类型
  String? groupDescription; // 群公告
  String? myAlias; // 发送人在本群的昵称
  String? content; // 消息数据（群成员列表）

  PartyRequest(String ownerPeerId, String peerId, String name)
      : super(ownerPeerId, peerId, name);

  PartyRequest.fromJson(Map json)
      : requestType = json['requestType'],
        groupDescription = json['groupDescription'],
        myAlias = json['myAlias'],
        messageId = json['messageId'],
        targetPeerId = json['targetPeerId'],
        targetType = json['targetType'],
        content = json['content'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'requestType': requestType,
      'groupDescription': groupDescription,
      'myAlias': myAlias,
      'messageId': messageId,
      'targetPeerId': targetPeerId,
      'targetType': targetType,
      'content': content,
    });
    return json;
  }
}

// 组（群聊/频道）
class Group extends Party {
  String? groupCategory; // 组类别，包括：Chat（群聊）, Channel（频道）
  String?
      groupType; // 组类型，包括：Private（私有，群聊群主才能添加成员，频道外部不可见）, Public（公有，群聊非群主也能添加成员，频道外部可见）
  String? description; // 组描述
  String? pyDescription; // 组描述拼音
  String? myAlias; // 我在本群的昵称
  String? groupOwnerPeerId; // 群主peerId
  List<Linkman> members = [];

  Group(String ownerPeerId, String peerId, String name)
      : super(ownerPeerId, peerId, name);

  Group.fromJson(Map json)
      : groupCategory = json['groupCategory'],
        groupType = json['groupType'],
        description = json['description'],
        pyDescription = json['pyDescription'],
        myAlias = json['myAlias'],
        groupOwnerPeerId = json['groupOwnerPeerId'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'groupCategory': groupCategory,
      'groupType': groupType,
      'description': description,
      'pyDescription': pyDescription,
      'myAlias': myAlias,
      'groupOwnerPeerId': groupOwnerPeerId,
    });
    return json;
  }
}

enum MemberType { owner, admin, member }

// 组成员
class GroupMember extends StatusEntity {
  String ownerPeerId; // 区分本地不同peerClient属主
  String? groupId; // 外键（对应group-groupId）
  String? memberPeerId; // 外键（对应linkman-peerId）
  String? memberAlias; // 成员别名
  String?
      memberType; // 成员类型，包括：Owner（创建者/群主，默认管理员）, Member（一般成员）,…可能的扩充：Admin（管理员）, Subscriber（订阅者）
  GroupMember(this.ownerPeerId);

  GroupMember.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        groupId = json['groupId'],
        memberPeerId = json['memberPeerId'],
        memberAlias = json['memberAlias'],
        memberType = json['memberType'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'groupId': groupId,
      'memberPeerId': memberPeerId,
      'memberAlias': memberAlias,
      'memberType': memberType,
    });
    return json;
  }
}

/// 手机联系人,从移动设备中读取出来的
class Contact extends Party {
  String? formattedName;
  String? trustLevel;
  bool isLinkman = false;

  Contact(String ownerPeerId, String peerId, String name)
      : super(ownerPeerId, peerId, name);

  Contact.fromJson(Map json)
      : formattedName = json['formattedName'],
        trustLevel = json['trustLevel'],
        isLinkman =
            json['isLinkman'] == true || json['isLinkman'] == 1 ? true : false,
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'formattedName': formattedName,
      'trustLevel': trustLevel,
      'isLinkman': isLinkman,
    });
    return json;
  }
}
