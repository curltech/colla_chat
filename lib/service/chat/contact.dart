import 'package:colla_chat/service/servicelocator.dart';
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

class PartyRequestService extends GeneralBaseService<PartyRequest> {
  PartyRequestService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return PartyRequest.fromJson(map);
    };
  }
}

final partyRequestService = PartyRequestService(
    tableName: "chat_partyrequest",
    indexFields: [
      'ownerPeerId',
      'createDate',
      'targetPeerId',
      'targetType',
      'status',
    ],
    fields: ServiceLocator.buildFields(PartyRequest('', '', ''), []));

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

  /// ????????????????????????????????????peerContacts??????????????????????????????????????????peerId
  /// @param {*} peerContacts
  /// @param {*} linkmans
  fillPeerContact(List<dynamic> peerContacts, List<Linkman> linkmans) async {
    List<flutter_contacts.Contact> contacts = await ContactUtil.getContacts();
    // ?????????????????????????????????????????????????????????????????????????????????????????????
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
    // ??????????????????????????????????????????????????????
    List<Map> pContacts = await findAll() as List<Map>;
    if (pContacts.isNotEmpty) {
      for (var pContact in pContacts) {
        // ???????????????????????????????????????????????????????????????
        var peerContact = peerContactMap[pContact['mobile']];
        if (peerContact) {
          peerContacts.add(pContact);
          peerContactMap.remove(pContact['mobile']);
        } else {
          // ?????????????????????????????????????????????
          this.delete(pContact);
        }
      }
    }
    // ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
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
          peerContact.isLinkman = true;

          return peerContact;
        }
      }
    }
    return null;
  }

  // ??????????????????????????????peerClient
  Future<Contact?> refresh(Contact peerContact) async {
    var mobile = peerContact.mobile;
    if (mobile != null) {
      var mobileNumber = await formatMobile(mobile);
      var peer = await peerClientService.findOneEffectiveByMobile(mobileNumber);
      if (peer != null) {
        var peerClient = peer as PeerClient;
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
