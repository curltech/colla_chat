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

// 联系人，或者叫好友
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
  bool locked = false; // 是否锁定，包括：true（锁定）, false（未锁定）
  bool notAlert = false; // 消息免打扰，包括：true（提醒）, false（免打扰）
  bool top = false; // 是否置顶，包括：true（置顶）, false（不置顶）
  bool blackedMe = false; // true-对方已将你加入黑名单
  bool droppedMe = false; // true-对方已将你从好友中删除

  // 非持久化属性
  //activeStatus: 活动状态，包括：Up（连接）, Down（未连接）
  //downloadSwitch: 自动下载文件开关
  //udpSwitch: 启用UDP开关
  //groupChats: 关联群聊列表
  //tag: 标签
  //pyTag: 标签拼音
  String? activeStatus;
  bool recallTimeLimit = false;
  bool recallAlert = false;
  bool myselfRecallTimeLimit = false;
  bool myselfRecallAlert = false;

  Linkman();

  Linkman.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        peerId = json['peerId'],
        name = json['name'],
        pyName = json['pyName'],
        mobile = json['mobile'],
        avatar = json['avatar'],
        publicKey = json['publicKey'],
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
      'avatar': avatar,
      'publicKey': publicKey,
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

// 联系人标签
class LinkmanTag extends BaseEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? name; // 标签名称
  LinkmanTag();

  LinkmanTag.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        name = json['name'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'name': name,
    });
    return json;
  }
}

// 联系人标签关系
class LinkmanTagLinkman extends BaseEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? tagId; // 标签主键_id
  String? linkmanPeerId; // 联系人peerId
  LinkmanTagLinkman();

  LinkmanTagLinkman.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        tagId = json['tagId'],
        linkmanPeerId = json['linkmanPeerId'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'tagId': tagId,
      'linkmanPeerId': linkmanPeerId,
    });
    return json;
  }
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

  LinkmanRequest();

  LinkmanRequest.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        senderPeerId = json['senderPeerId'],
        name = json['name'],
        mobile = json['mobile'],
        avatar = json['avatar'],
        publicKey = json['publicKey'],
        receiverPeerId = json['receiverPeerId'],
        requestType = json['requestType'],
        receiveTime = json['receiveTime'],
        message = json['message'],
        groupId = json['groupId'],
        groupCreateDate = json['groupCreateDate'],
        groupName = json['groupName'],
        groupDescription = json['groupDescription'],
        myAlias = json['myAlias'],
        data = json['data'],
        blackedMe = json['blackedMe'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'senderPeerId': senderPeerId,
      'name': name,
      'mobile': mobile,
      'avatar': avatar,
      'publicKey': publicKey,
      'receiverPeerId': receiverPeerId,
      'requestType': requestType,
      'receiveTime': receiveTime,
      'message': message,
      'groupId': groupId,
      'groupCreateDate': groupCreateDate,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'myAlias': myAlias,
      'data': data,
      'blackedMe': blackedMe,
    });
    return json;
  }
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
  bool locked = false; // 是否锁定（群聊不使用，频道使用），包括：true（锁定）, false（未锁定）
  bool alert = false; // 是否提醒，包括：true（提醒）, false（免打扰）
  bool top = false; // 是否置顶，包括：true（置顶）, false（不置顶）
  String? myAlias; // 我在本群的昵称

//this.avatar = null // 头像（保留，适用于频道）
//this.shareLink = null // 分享链接（保留，适用于频道）

// 非持久化属性（群聊groupChat）
//activeStatus: 活动状态（除自己以外至少一个成员activeStatus为Up，则为Up，否则为Down），包括：Up（有连接）, Down（无连接）
//groupOwnerPeerId: 群主peerId

  Group();

  Group.fromJson(Map json)
      : ownerPeerId = json['ownerPeerId'],
        groupId = json['groupId'],
        groupCategory = json['groupCategory'],
        groupType = json['groupType'],
        name = json['name'],
        description = json['description'],
        givenName = json['givenName'],
        pyGivenName = json['pyGivenName'],
        tag = json['tag'],
        pyName = json['pyName'],
        pyDescription = json['pyDescription'],
        pyTag = json['pyTag'],
        locked = json['locked'] == true || json['locked'] == 1 ? true : false,
        alert = json['alert'] == true || json['alert'] == 1 ? true : false,
        top = json['top'] == true || json['top'] == 1 ? true : false,
        myAlias = json['myAlias'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ownerPeerId': ownerPeerId,
      'groupId': groupId,
      'groupCategory': groupCategory,
      'groupType': groupType,
      'name': name,
      'description': description,
      'givenName': givenName,
      'pyGivenName': pyGivenName,
      'tag': tag,
      'pyName': pyName,
      'pyDescription': pyDescription,
      'pyTag': pyTag,
      'locked': locked,
      'alert': alert,
      'top': top,
      'myAlias': myAlias,
    });
    return json;
  }
}

// 组成员
class GroupMember extends StatusEntity {
  String? ownerPeerId; // 区分本地不同peerClient属主
  String? groupId; // 外键（对应group-groupId）
  String? memberPeerId; // 外键（对应linkman-peerId）
  String? memberAlias; // 成员别名
  String?
      memberType; // 成员类型，包括：Owner（创建者/群主，默认管理员）, Member（一般成员）,…可能的扩充：Admin（管理员）, Subscriber（订阅者）
  GroupMember();

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
class Contact extends StatusEntity {
  String? peerId;
  String? name;
  String? formattedName;
  String? mobile;
  String? trustLevel;
  String? publicKey;
  String? avatar;
  String? pyName;
  String? givenName;
  String? pyGivenName;
  bool locked = false;
  bool isLinkman = false;

  Contact();

  Contact.fromJson(Map json)
      : peerId = json['peerId'],
        name = json['name'],
        formattedName = json['formattedName'],
        mobile = json['mobile'],
        trustLevel = json['trustLevel'],
        publicKey = json['publicKey'],
        avatar = json['avatar'],
        pyName = json['pyName'],
        givenName = json['givenName'],
        pyGivenName = json['pyGivenName'],
        locked = json['locked'] == true || json['locked'] == 1 ? true : false,
        isLinkman =
            json['isLinkman'] == true || json['isLinkman'] == 1 ? true : false,
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'peerId': peerId,
      'name': name,
      'formattedName': formattedName,
      'mobile': mobile,
      'trustLevel': trustLevel,
      'publicKey': publicKey,
      'avatar': avatar,
      'pyName': pyName,
      'givenName': givenName,
      'pyGivenName': pyGivenName,
      'locked': locked,
      'isLinkman': isLinkman,
    });
    return json;
  }
}
