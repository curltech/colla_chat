import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/peer_party.dart';

// 组（群聊/频道）
class Group extends PeerParty {
  String? groupCategory; // 组类别，包括：Chat（群聊）, Channel（频道）
  String?
      groupType; // 组类型，包括：Private（私有，群聊群主才能添加成员，频道外部不可见）, Public（公有，群聊非群主也能添加成员，频道外部可见）
  String? description; // 组描述
  String? pyDescription; // 组描述拼音
  String? myAlias; // 我在本群的昵称
  String? groupOwnerPeerId; // 群主peerId
  String? peerPrivateKey;
  String? privateKey;
  String? signalPublicKey;
  String? signalPrivateKey;

  Group(String peerId, String name) : super(peerId, name);

  Group.fromJson(Map json)
      : groupCategory = json['groupCategory'],
        groupType = json['groupType'],
        description = json['description'],
        pyDescription = json['pyDescription'],
        myAlias = json['myAlias'],
        groupOwnerPeerId = json['groupOwnerPeerId'],
        peerPrivateKey = json['peerPrivateKey'],
        privateKey = json['privateKey'],
        signalPublicKey = json['signalPublicKey'],
        signalPrivateKey = json['signalPrivateKey'],
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
      'peerPrivateKey': peerPrivateKey,
      'privateKey': privateKey,
      'signalPublicKey': signalPublicKey,
      'signalPrivateKey': signalPrivateKey,
    });
    return json;
  }
}

enum MemberType { owner, admin, member }

// 组成员
class GroupMember extends StatusEntity {
  String? groupId; // 外键（对应group-groupId）
  String? memberPeerId; // 外键（对应peerclient-peerId）
  String? memberAlias; // 成员别名
  String? creatorPeerId;
  String?
      memberType; // 成员类型，包括：Owner（创建者/群主，默认管理员）, Member（一般成员）,…可能的扩充：Admin（管理员）, Subscriber（订阅者）
  GroupMember();

  GroupMember.fromJson(Map json)
      : groupId = json['groupId'],
        memberPeerId = json['memberPeerId'],
        memberAlias = json['memberAlias'],
        memberType = json['memberType'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'groupId': groupId,
      'memberPeerId': memberPeerId,
      'memberAlias': memberAlias,
      'memberType': memberType,
    });
    return json;
  }
}
