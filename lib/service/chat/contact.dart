import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;

import '../../entity/chat/contact.dart';
import '../../entity/dht/peerclient.dart';
import '../../tool/util.dart';
import '../../widgets/common/image_widget.dart';
import '../dht/peerclient.dart';
import '../general_base.dart';

abstract class PartyService<T> extends GeneralBaseService<T> {
  PartyService(
      {required super.tableName,
      required super.fields,
      required super.indexFields});

  Future<T?> findOneByPeerId(String peerId) async {
    var where = 'peerId = ?';
    var whereArgs = [peerId];
    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }

  Future<T?> findOneByName(String name) async {
    var where = 'name = ?';
    var whereArgs = [name];
    var peer = await findOne(where: where, whereArgs: whereArgs);

    return peer;
  }
}

class LinkmanService extends PartyService<Linkman> {
  Map<String, Linkman> linkmen = {};

  LinkmanService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Linkman.fromJson(map);
    };
  }

  Future<List<Linkman>> search(String key) async {
    var where = 'peerId=? or mobile=? or name=? or pyName=? or mail=?';
    var whereArgs = [key, key, key, key, key];
    var linkmen = await find(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'pyName',
    );
    return linkmen;
  }

  Future<Linkman?> findCachedOneByPeerId(String peerId) async {
    if (linkmen.containsKey(peerId)) {
      return linkmen[peerId];
    }
    Linkman? linkman = await findOneByPeerId(peerId);
    if (linkman != null) {
      String? avatar = linkman.avatar;
      if (avatar != null) {
        var avatarImage = ImageWidget(
          image: avatar,
          height: 32,
          width: 32,
        );
        linkman.avatarImage = avatarImage;
      }
      linkmen[peerId] = linkman;
    }
    return linkman;
  }

  ///发出linkman邀请，把自己的详细的信息发出，当邀请被同意后，就会收到对方详细的信息
  ///一般来说，采用websocket发送信息，是chainmessage，其中的payload是chatmessage
  ///而采用webrtc时，直接是chatmessage，content里面是实际的信息
  Future<void> requestLinkman(Linkman linkman) async {}

  ///把peerclient加入自己的好友
  Future<void> addLinkman(PeerClient peerClient) async {
    Linkman? linkman = await findCachedOneByPeerId(peerClient.peerId);
    if (linkman == null) {
      linkman = Linkman.fromJson(peerClient.toJson());
      await insert(linkman);
      linkmen[linkman.peerId] = linkman;
      await chatSummaryService.upsertByLinkman(linkman);
    } else {
      var id = linkman.id;
      linkman = Linkman.fromJson(peerClient.toJson());
      linkman.id = id;
      await update(linkman);
      linkmen[linkman.peerId] = linkman;
      await chatSummaryService.upsertByLinkman(linkman);
    }
    await peerClientService.update({'id': peerClient.id, 'linkman': true});
  }
}

final linkmanService = LinkmanService(
    tableName: 'chat_linkman',
    indexFields: [
      'givenName',
      'name',
      'ownerPeerId',
      'peerId',
      'mobile',
    ],
    fields: ServiceLocator.buildFields(Linkman('', '', ''), []));

class TagService extends GeneralBaseService<Tag> {
  TagService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Tag.fromJson(map);
    };
  }
}

final tagService = TagService(
    tableName: "chat_tag",
    indexFields: ['ownerPeerId', 'createDate', 'tag'],
    fields: ServiceLocator.buildFields(Tag(''), []));

class PartyTagService extends GeneralBaseService<PartyTag> {
  PartyTagService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return PartyTag.fromJson(map);
    };
  }
}

final partyTagService = PartyTagService(
    tableName: "chat_partytag",
    indexFields: ['ownerPeerId', 'createDate', 'tag', 'partyPeerId'],
    fields: ServiceLocator.buildFields(PartyTag(''), []));

class GroupService extends PartyService<Group> {
  Map<String, Group> groups = {};

  GroupService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Group.fromJson(map);
    };
  }

  Future<Group?> findCachedOneByPeerId(String peerId) async {
    if (groups.containsKey(peerId)) {
      return groups[peerId];
    }
    Group? group = await findOneByPeerId(peerId);
    if (group != null) {
      String? avatar = group.avatar;
      if (avatar != null) {
        var avatarImage = ImageWidget(
          image: avatar,
          height: 32,
          width: 32,
        );
        group.avatarImage = avatarImage;
      }
      groups[peerId] = group;
    }
    return group;
  }

  Future<Group> createGroup(Group group) async {
    var old = await findOneByName(group.name);
    if (old != null) {
      return old;
    }
    group.status = EntityStatus.effective.name;

    ///group peerId对应的密钥对
    SimpleKeyPair peerPrivateKey = await cryptoGraphy.generateKeyPair();
    SimplePublicKey peerPublicKey = await peerPrivateKey.extractPublicKey();
    group.peerPrivateKey =
        await cryptoGraphy.export(peerPrivateKey, myself.password!.codeUnits);
    group.peerPublicKey = await cryptoGraphy.exportPublicKey(peerPrivateKey);
    group.peerId = group.peerPublicKey!;

    ///加密对应的密钥对x25519
    SimpleKeyPair keyPair =
        await cryptoGraphy.generateKeyPair(keyPairType: KeyPairType.x25519);
    SimplePublicKey publicKey = await keyPair.extractPublicKey();
    group.privateKey =
        await cryptoGraphy.export(keyPair, myself.password!.codeUnits);
    group.publicKey = await cryptoGraphy.exportPublicKey(keyPair);

    return group;
  }

  Future<Group?> modify(Group group) async {
    Group? old = await findOneByPeerId(group.peerId);
    if (old != null) {
      group.id = old.id;
      group.createDate = old.createDate;
    }
    await upsert(group);
    groups[group.peerId];
    await chatSummaryService.upsertByGroup(group);
    List<PeerParty> members = group.members;
    if (members.isNotEmpty) {
      for (var member in members) {
        GroupMember groupMember = GroupMember(myself.peerId!);
        groupMember.memberPeerId = member.peerId;
        groupMember.groupId = group.peerId;
        groupMember.memberAlias = member.alias;
        groupMemberService.modify(groupMember);
      }
    }
    return group;
  }
}

final groupService = GroupService(
    tableName: "chat_group",
    indexFields: [
      'givenName',
      'name',
      'description',
      'ownerPeerId',
      'createDate',
      'peerId',
      'groupCategory',
      'groupType'
    ],
    fields: ServiceLocator.buildFields(Group('', '', ''), []));

class GroupMemberService extends GeneralBaseService<GroupMember> {
  GroupMemberService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return GroupMember.fromJson(map);
    };
  }

  Future<List<GroupMember>> findByGroupId(String groupId) async {
    String where = 'groupId=?';
    List<Object> whereArgs = [groupId];
    List<GroupMember> groupMembers =
        await find(where: where, whereArgs: whereArgs);

    return groupMembers;
  }

  Future<GroupMember?> findOneByGroupId(
      String groupId, String memberPeerId) async {
    String where = 'groupId=? and memberPeerId=?';
    List<Object> whereArgs = [groupId, memberPeerId];
    return await findOne(where: where, whereArgs: whereArgs);
  }

  Future<List<Linkman>> findLinkmen(List<GroupMember> groupMembers) async {
    List<Linkman> linkmen = [];
    if (groupMembers.isNotEmpty) {
      for (var groupMember in groupMembers) {
        var peerId = groupMember.memberPeerId;
        if (peerId != null) {
          Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
          if (linkman != null) {
            linkmen.add(linkman);
          }
        }
      }
    }
    return linkmen;
  }

  Future<void> modify(GroupMember groupMember) async {
    GroupMember? old =
        await findOneByGroupId(groupMember.groupId!, groupMember.memberPeerId!);
    if (old != null) {
      groupMember.id = old.id;
      groupMember.createDate = old.createDate;
    }
    upsert(groupMember);
  }
}

final groupMemberService = GroupMemberService(
    tableName: "chat_groupmember",
    indexFields: [
      'ownerPeerId',
      'createDate',
      'groupId',
      'memberPeerId',
      'memberType'
    ],
    fields: ServiceLocator.buildFields(GroupMember(''), []));

class ContactService extends PartyService<Contact> {
  ContactService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Contact.fromJson(map);
    };
  }

  Future<String> formatMobile(String mobile) async {
    return mobile;
  }

  /// 获取手机电话本的数据填充peerContacts数组，校验是否好友，是否存在peerId
  /// @param {*} peerContacts
  /// @param {*} linkmans
  fillPeerContact(List<dynamic> peerContacts, List<Linkman> linkmans) async {
    List<flutter_contacts.Contact> contacts = await ContactUtil.getContacts();
    // 把通讯录的数据规整化，包含手机号和名称，然后根据手机号建立索引
    var peerContactMap = Map();
    if (contacts.isNotEmpty) {
      for (var contact in contacts) {
        Contact peerContact =
            Contact('', '', contact.name.last + contact.name.first);
        if (contact.name != null) {
          peerContact.formattedName = contact.name.toString();
          //peerContact.pyFormattedName = pinyinUtil.getPinyin(peerContact.formattedName);
        }
        if (contact.phones != null && contact.phones.isNotEmpty) {
          for (var phoneNumber in contact.phones) {
            if (phoneNumber.isPrimary) {
              peerContact.mobile = phoneNumber.normalizedNumber;
              break;
            }
          }
          if (peerContact.mobile == null) {
            var mobile = contact.phones[0].normalizedNumber;
            peerContact.mobile = await formatMobile(mobile);
          }
        }
        peerContactMap[peerContact.mobile] = peerContact;
      }
    }
    // 遍历本地库的记录，根据手机号检查索引
    List<Map> pContacts = await findAll() as List<Map>;
    if (pContacts.isNotEmpty) {
      for (var pContact in pContacts) {
        // 如果通讯录中存在，将本地匹配记录放入结果集
        var peerContact = peerContactMap[pContact['mobile']];
        if (peerContact) {
          peerContacts.add(pContact);
          peerContactMap.remove(pContact['mobile']);
        } else {
          // 如果通讯录不存在，则本地库删除
          this.delete(pContact);
        }
      }
    }
    // 通讯录中剩余的记录，新增的记录将被检查好友记录和服务器记录，然后插入本地库并加入结果集
    var leftPeerContacts = peerContactMap.values;
    if (leftPeerContacts != null) {
      for (var leftPeerContact in leftPeerContacts) {
        var pc = this.updateByLinkman(leftPeerContact, linkmans);
        if (pc == null) {
          pc = await this.refresh(leftPeerContact);
        }
        if (pc != null) {
          this.insert(leftPeerContact);
        }
        peerContacts.add(leftPeerContact);
      }
    }
  }

  Contact? updateByLinkman(Contact peerContact, List<Linkman> linkmans) {
    if (linkmans.isNotEmpty) {
      for (var linkman in linkmans) {
        if (linkman.mobile == peerContact.mobile) {
          peerContact.peerId = linkman.peerId;
          peerContact.name = linkman.name;
          peerContact.pyName = linkman.pyName;
          peerContact.givenName = linkman.givenName;
          peerContact.pyGivenName = linkman.pyGivenName;
          peerContact.locked = linkman.locked;
          peerContact.status = linkman.status;
          peerContact.publicKey = linkman.publicKey;
          peerContact.avatar = linkman.avatar;
          peerContact.linkman = true;

          return peerContact;
        }
      }
    }
    return null;
  }

  // 从服务器端获取是否有peerClient
  Future<Contact?> refresh(Contact peerContact) async {
    var mobile = peerContact.mobile;
    if (mobile != null) {
      var mobileNumber = await formatMobile(mobile);
      var peerClient =
          await peerClientService.findOneEffectiveByMobile(mobileNumber);
      if (peerClient != null) {
        peerContact.peerId = peerClient.peerId!;
        peerContact.name = peerClient.name;
        peerContact.status = peerClient.status;
        peerContact.publicKey = peerClient.publicKey;

        return peerContact;
      }
    }

    return null;
  }
}

final contactService = ContactService(
    tableName: "chat_contact",
    indexFields: ['peerId', 'mobile', 'formattedName', 'name'],
    fields: ServiceLocator.buildFields(Contact('', '', ''), []));
