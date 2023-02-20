//当事方，联系人，群，手机联系人（潜在联系人）的共同父类
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/dht/base.dart';

abstract class PeerParty extends PeerEntity {
  String? alias; // 别名
  String? pyName; // 用户名拼音
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

  bool downloadSwitch = true; //: 自动下载文件开关
  bool udpSwitch = false; //: 启用UDP开关
  String? groupChats; // 关联群聊列表
  String? tag; //: 标签
  String? pyTag; //: 标签拼音
  List<Tag> tags = [];

  PeerParty(String peerId, String name) : super(peerId, name);

  PeerParty.fromJson(Map json)
      : alias = json['alias'],
        pyName = json['pyName'],
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
      'alias': alias,
      'pyName': pyName,
      'givenName': givenName,
      'pyGivenName': pyGivenName,
      'sourceType': sourceType,
      'lastConnectTime': lastConnectTime,
      'locked': locked,
      'notAlert': notAlert,
      'top': top,
      'blackedMe': blackedMe,
      'droppedMe': droppedMe,
      'recallTimeLimit': recallTimeLimit,
      'recallAlert': recallAlert,
      'myselfRecallTimeLimit': myselfRecallTimeLimit,
      'myselfRecallAlert': myselfRecallAlert,
    });
    return json;
  }
}

// 联系人标签
class Tag extends BaseEntity {
  String? tag; // 标签名称
  Tag();

  Tag.fromJson(Map json)
      : tag = json['tag'],
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
  String? tag; // 标签
  String? partyPeerId; // party peerId
  String? partyType; // party type:linkman,group,channel,contact
  PartyTag();

  PartyTag.fromJson(Map json)
      : tag = json['tag'],
        partyPeerId = json['partyPeerId'],
        partyType = json['partyType'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'tag': tag,
      'partyPeerId': partyPeerId,
      'partyType': partyType,
    });
    return json;
  }
}
