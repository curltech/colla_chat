import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/service/dht/base.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/contact_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;

abstract class PeerPartyService<T> extends PeerEntityService<T> {
  PeerPartyService(
      {required super.tableName,
      required super.fields,
      required super.indexFields});
}

class LinkmanService extends PeerPartyService<Linkman> {
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
    if (StringUtil.isEmpty(key)) {
      return await findAll();
    }
    var where = 'peerId=? or mobile=? or name=? or pyName=? or email=?';
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
        var avatarImage = ImageUtil.buildImageWidget(
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

  Future<Widget> findAvatarImageWidget(String peerId) async {
    Widget image = defaultImage;
    var linkman = await findCachedOneByPeerId(peerId);
    if (linkman != null && linkman.avatarImage != null) {
      image = linkman.avatarImage!;
    }
    return image;
  }

  ///发出linkman邀请，把自己的详细的信息发出，当邀请被同意后，就会收到对方详细的信息
  ///一般来说，采用websocket发送信息，是chainmessage，其中的payload是chatmessage
  ///而采用webrtc时，直接是chatmessage，content里面是实际的信息
  Future<void> requestLinkman(Linkman linkman) async {}

  Future<void> store(Linkman linkman) async {
    Linkman? old = await findCachedOneByPeerId(linkman.peerId);
    if (old == null) {
      await insert(linkman);
      linkmen[linkman.peerId] = linkman;
      await chatSummaryService.upsertByLinkman(linkman);
    } else {
      linkman.id = old.id;
      await update(linkman);
      linkmen[linkman.peerId] = linkman;
      await chatSummaryService.upsertByLinkman(linkman);
    }
    await refresh(linkman.peerId);
  }

  ///通过peerclient增加或者修改
  Future<Linkman> storeByPeerClient(PeerClient peerClient,
      {LinkmanStatus? linkmanStatus}) async {
    String peerId = peerClient.peerId;
    Linkman? linkman = await findCachedOneByPeerId(peerId);
    Map<String, dynamic> map = peerClient.toJson();
    if (linkman == null) {
      linkman = Linkman.fromJson(map);
      if (linkmanStatus != null) {
        linkman.status = linkmanStatus.name;
      }
      linkman.id = null;
      await insert(linkman);
      linkmen[peerId] = linkman;
      await chatSummaryService.upsertByLinkman(linkman);
    } else {
      int? id = linkman.id;
      String? status = linkman.status;
      linkman = Linkman.fromJson(map);
      linkman.id = id;
      if (linkmanStatus != null) {
        linkman.status = linkmanStatus.name;
      } else {
        linkman.status = status;
      }
      await update(linkman);
      linkmen[peerId] = linkman;
      await chatSummaryService.upsertByLinkman(linkman);
    }
    await refresh(peerId);

    return linkman;
  }

  ///发出加好友的请求
  Future<ChatMessage> addFriend(String peerId, String title,
      {TransportType transportType = TransportType.webrtc,
      CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    // 加好友会发送自己的信息，回执将收到对方的信息
    String json = JsonUtil.toJsonString(myself.myselfPeer);
    List<int> data = CryptoUtil.stringToUtf8(json);
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(peerId,
        data: data,
        subMessageType: ChatMessageSubType.addFriend,
        transportType: transportType,
        title: title);
    return await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: cryptoOption);
  }

  ///接收到加好友的请求，发送回执
  Future<ChatMessage> receiveAddFriend(
      ChatMessage chatMessage, MessageStatus receiptType) async {
    String json = JsonUtil.toJsonString(myself.myselfPeer);
    ChatMessage? chatReceipt =
        await chatMessageService.buildChatReceipt(chatMessage, receiptType);
    if (receiptType == MessageStatus.accepted) {
      chatReceipt!.content = json;
    }
    return await chatMessageService.sendAndStore(chatReceipt!);
  }

  ///接收到加好友的回执
  Future<Linkman> receiveAddFriendReceipt(ChatMessage chatReceipt) async {
    Uint8List data = CryptoUtil.decodeBase64(chatReceipt.content!);
    String json = CryptoUtil.utf8ToString(data);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    PeerClient peerClient = PeerClient.fromJson(map);
    return await linkmanService.storeByPeerClient(peerClient);
  }

  ///发出更新好友信息的请求
  Future<ChatMessage> modifyFriend(String peerId,
      {String? clientId,
      CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    // 加好友会发送自己的信息，回执将收到对方的信息
    Map<String, dynamic> map = JsonUtil.toJson(myself.myselfPeer);
    PeerClient peerClient = PeerClient.fromJson(map);
    String json = JsonUtil.toJsonString(peerClient);
    List<int> data = CryptoUtil.stringToUtf8(json);
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
      peerId,
      clientId: clientId,
      data: data,
      messageType: ChatMessageType.system,
      subMessageType: ChatMessageSubType.modifyFriend,
    );
    return await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: cryptoOption);
  }

  ///接收到更新好友信息的请求
  receiveModifyFriend(ChatMessage chatMessage, String content) async {
    Map<String, dynamic> map = JsonUtil.toJson(content);
    PeerClient peerClient = PeerClient.fromJson(map);
    await peerClientService.store(peerClient);
  }

  refresh(String peerId) {
    linkmen.remove(peerId);
  }

  ///更新头像
  @override
  Future<String> updateAvatar(String peerId, List<int> avatar) async {
    String data = await super.updateAvatar(peerId, avatar);
    refresh(peerId);

    return data;
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
    fields: ServiceLocator.buildFields(Linkman('', ''), []));

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
    fields: ServiceLocator.buildFields(Tag(), []));

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
    fields: ServiceLocator.buildFields(PartyTag(), []));

class GroupService extends PeerPartyService<Group> {
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
        var avatarImage = ImageUtil.buildImageWidget(
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

  Future<Group> createGroup(String name) async {
    var old = await findOneByName(name);
    if (old != null) {
      return old;
    }

    ///group peerId对应的密钥对
    SimpleKeyPair peerPrivateKey = await cryptoGraphy.generateKeyPair();
    SimplePublicKey peerPublicKey = await peerPrivateKey.extractPublicKey();
    var peerId = await cryptoGraphy.exportPublicKey(peerPrivateKey);
    var group = Group(peerId, name);
    group.peerPrivateKey =
        await cryptoGraphy.export(peerPrivateKey, myself.password!.codeUnits);
    group.peerPublicKey = peerId;
    group.peerId = peerId;

    group.status = EntityStatus.effective.name;

    ///加密对应的密钥对x25519
    SimpleKeyPair keyPair =
        await cryptoGraphy.generateKeyPair(keyPairType: KeyPairType.x25519);
    SimplePublicKey publicKey = await keyPair.extractPublicKey();
    group.privateKey =
        await cryptoGraphy.export(keyPair, myself.password!.codeUnits);
    group.publicKey = await cryptoGraphy.exportPublicKey(keyPair);

    return group;
  }

  Future<Group?> store(Group group) async {
    Group? old = await findOneByPeerId(group.peerId);
    if (old != null) {
      group.id = old.id;
      group.createDate = old.createDate;
    }
    await upsert(group);
    groups[group.peerId];
    await chatSummaryService.upsertByGroup(group);
    List<PeerParty> members = group.memberPeers;
    if (members.isNotEmpty) {
      for (var member in members) {
        GroupMember groupMember = GroupMember();
        groupMember.memberPeerId = member.peerId;
        groupMember.groupId = group.peerId;
        groupMember.memberAlias = member.alias;
        groupMemberService.store(groupMember);
      }
    }
    return group;
  }

  Future<List<Group>> search(String key) async {
    if (StringUtil.isEmpty(key)) {
      return await findAll();
    }
    var where = 'peerId=? or mobile=? or name=? or myAlias=? or email=?';
    var whereArgs = [key, key, key, key, key];
    var groups = await find(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'pyName',
    );
    return groups;
  }

  addGroup(Group group) async {
    String json = JsonUtil.toJsonString(group);
    List<int> data = CryptoUtil.stringToUtf8(json);
    List<ChatMessage> chatMessages =
        await chatMessageService.buildGroupChatMessage(
      group.peerId,
      data: data,
      subMessageType: ChatMessageSubType.addGroup,
    );
    for (var chatMessage in chatMessages) {
      await chatMessageService.sendAndStore(chatMessage);
    }
  }

  receiveAddGroup(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);
    String json = CryptoUtil.utf8ToString(data);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    Group group = Group.fromJson(map);
    groupService.store(group);
    ChatMessage? chatReceipt = await chatMessageService.buildChatReceipt(
        chatMessage, MessageStatus.accepted);

    await chatMessageService.sendAndStore(chatReceipt!);
  }

  receiveAddGroupReceipt(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);
    String json = CryptoUtil.utf8ToString(data);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    Group group = Group.fromJson(map);
    groupService.store(group);
    ChatMessage? chatReceipt = await chatMessageService.buildChatReceipt(
        chatMessage, MessageStatus.accepted);

    await chatMessageService.sendAndStore(chatReceipt!);
  }

  modifyGroup(Group group) async {
    String json = JsonUtil.toJsonString(group);
    List<int> data = CryptoUtil.stringToUtf8(json);
    List<ChatMessage> chatMessages =
        await chatMessageService.buildGroupChatMessage(
      group.peerId,
      data: data,
      subMessageType: ChatMessageSubType.modifyGroup,
    );
    for (var chatMessage in chatMessages) {
      await chatMessageService.sendAndStore(chatMessage);
    }
  }

  receiveModifyGroup(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);
    String json = CryptoUtil.utf8ToString(data);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    Group group = Group.fromJson(map);
    groupService.store(group);
    ChatMessage? chatReceipt = await chatMessageService.buildChatReceipt(
        chatMessage, MessageStatus.accepted);

    await chatMessageService.sendAndStore(chatReceipt!);
  }

  receiveModifyGroupReceipt(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);
    String json = CryptoUtil.utf8ToString(data);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    Group group = Group.fromJson(map);
    groupService.store(group);
    ChatMessage? chatReceipt = await chatMessageService.buildChatReceipt(
        chatMessage, MessageStatus.accepted);

    await chatMessageService.sendAndStore(chatReceipt!);
  }

  dismissGroup(Group group) async {
    await groupMemberService.delete(entity: {
      'groupId': group.id,
    });
    await groupService.delete(entity: {
      'groupId': group.id,
    });
    await chatMessageService.delete(entity: {
      'receiverPeerId': group.id,
    });
    await chatMessageService.delete(entity: {
      'senderPeerId': group.id,
    });
    await chatSummaryService.delete(entity: {
      'peerId': group.id,
    });
    List<ChatMessage> chatMessages =
        await chatMessageService.buildGroupChatMessage(
      group.peerId,
      title: group.peerId,
      subMessageType: ChatMessageSubType.dismissGroup,
    );
    for (var chatMessage in chatMessages) {
      await chatMessageService.sendAndStore(chatMessage);
    }
  }

  receiveDismissGroup(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);
    String json = CryptoUtil.utf8ToString(data);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    Group group = Group.fromJson(map);
    await groupMemberService.delete(entity: {
      'groupId': group.id,
    });
    await groupService.delete(entity: {
      'groupId': group.id,
    });
    await chatMessageService.delete(entity: {
      'receiverPeerId': group.id,
    });
    await chatMessageService.delete(entity: {
      'senderPeerId': group.id,
    });
    await chatSummaryService.delete(entity: {
      'peerId': group.id,
    });
    ChatMessage? chatReceipt = await chatMessageService.buildChatReceipt(
        chatMessage, MessageStatus.accepted);

    await chatMessageService.sendAndStore(chatReceipt!);
  }

  addGroupMember(String groupId, List<GroupMember> groupMembers) async {
    String json = JsonUtil.toJsonString(groupMembers);
    List<int> data = CryptoUtil.stringToUtf8(json);
    List<ChatMessage> chatMessages =
        await chatMessageService.buildGroupChatMessage(
      groupId,
      data: data,
      subMessageType: ChatMessageSubType.addGroupMember,
    );
    for (var chatMessage in chatMessages) {
      await chatMessageService.sendAndStore(chatMessage);
    }
  }

  receiveAddGroupMember(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);
    String json = CryptoUtil.utf8ToString(data);
    List<Map<String, dynamic>> maps = JsonUtil.toJson(json);
    List<GroupMember> groupMembers = [];
    for (var map in maps) {
      GroupMember groupMember = GroupMember.fromJson(map);
      groupMembers.add(groupMember);
      groupMemberService.store(groupMember);
    }

    ChatMessage? chatReceipt = await chatMessageService.buildChatReceipt(
        chatMessage, MessageStatus.accepted);

    await chatMessageService.sendAndStore(chatReceipt!);
  }

  receiveAddGroupMemberReceipt(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);
    String json = CryptoUtil.utf8ToString(data);
    List<Map<String, dynamic>> maps = JsonUtil.toJson(json);
    List<GroupMember> groupMembers = [];
    for (var map in maps) {
      GroupMember groupMember = GroupMember.fromJson(map);
      groupMembers.add(groupMember);
      groupMemberService.store(groupMember);
    }

    ChatMessage? chatReceipt = await chatMessageService.buildChatReceipt(
        chatMessage, MessageStatus.accepted);

    await chatMessageService.sendAndStore(chatReceipt!);
  }

  removeGroupMember(String groupId, List<GroupMember> groupMembers) async {
    String json = JsonUtil.toJsonString(groupMembers);
    List<int> data = CryptoUtil.stringToUtf8(json);
    List<ChatMessage> chatMessages =
        await chatMessageService.buildGroupChatMessage(
      groupId,
      data: data,
      subMessageType: ChatMessageSubType.removeGroupMember,
    );
    for (var chatMessage in chatMessages) {
      await chatMessageService.sendAndStore(chatMessage);
    }
  }

  receiveRemoveGroupMember(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);
    String json = CryptoUtil.utf8ToString(data);
    List<Map<String, dynamic>> maps = JsonUtil.toJson(json);
    List<GroupMember> groupMembers = [];
    for (var map in maps) {
      GroupMember groupMember = GroupMember.fromJson(map);
      groupMembers.add(groupMember);
      groupMemberService.delete(entity: {
        'memberPeerId': groupMember.memberPeerId,
        'groupId': groupMember.groupId
      });
    }

    ChatMessage? chatReceipt = await chatMessageService.buildChatReceipt(
        chatMessage, MessageStatus.accepted);

    await chatMessageService.sendAndStore(chatReceipt!);
  }

  receiveRemoveGroupMemberReceipt(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);
    String json = CryptoUtil.utf8ToString(data);
    List<Map<String, dynamic>> maps = JsonUtil.toJson(json);
    List<GroupMember> groupMembers = [];
    for (var map in maps) {
      GroupMember groupMember = GroupMember.fromJson(map);
      groupMembers.add(groupMember);
      groupMemberService.delete(entity: {
        'memberPeerId': groupMember.memberPeerId,
        'groupId': groupMember.groupId
      });
    }

    ChatMessage? chatReceipt = await chatMessageService.buildChatReceipt(
        chatMessage, MessageStatus.accepted);

    await chatMessageService.sendAndStore(chatReceipt!);
  }

  groupFile(String groupId, List<int> data) async {
    List<ChatMessage> chatMessages =
        await chatMessageService.buildGroupChatMessage(
      groupId,
      data: data,
      subMessageType: ChatMessageSubType.groupFile,
    );
    for (var chatMessage in chatMessages) {
      await chatMessageService.sendAndStore(chatMessage);
    }
  }

  receiveGroupFile(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);
    String json = CryptoUtil.utf8ToString(data);
    List<Map<String, dynamic>> maps = JsonUtil.toJson(json);
    List<GroupMember> groupMembers = [];
    for (var map in maps) {
      GroupMember groupMember = GroupMember.fromJson(map);
      groupMembers.add(groupMember);
      groupMemberService.store(groupMember);
    }

    ChatMessage? chatReceipt = await chatMessageService.buildChatReceipt(
        chatMessage, MessageStatus.accepted);

    await chatMessageService.sendAndStore(chatReceipt!);
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
    fields: ServiceLocator.buildFields(Group('', ''), []));

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

  Future<void> store(GroupMember groupMember) async {
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
    fields: ServiceLocator.buildFields(GroupMember(), []));

class ContactService extends PeerPartyService<Contact> {
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
  Future<List<Contact>> syncContact() async {
    List<flutter_contacts.Contact> mobileContacts =
        await ContactUtil.getContacts();
    // 把通讯录的数据规整化，包含手机号和名称，然后根据手机号建立索引
    var mobileContactMap = {};
    if (mobileContacts.isNotEmpty) {
      for (var mobileContact in mobileContacts) {
        Contact contact =
            Contact('', mobileContact.name.last + mobileContact.name.first);
        contact.formattedName = contact.name.toString();
        //contact.pyFormattedName = pinyinUtil.getPinyin(contact.formattedName);
        if (mobileContact.phones.isNotEmpty) {
          for (var phoneNumber in mobileContact.phones) {
            if (phoneNumber.isPrimary) {
              contact.mobile = phoneNumber.normalizedNumber;
              break;
            }
          }
          if (contact.mobile == null) {
            var mobile = mobileContact.phones[0].normalizedNumber;
            contact.mobile = await formatMobile(mobile);
          }
        }
        mobileContactMap[contact.mobile] = contact;
      }
    }
    // 遍历本地库的记录，根据手机号检查索引
    List<Contact> lastContacts = [];
    List<Contact> contacts = await findAll();
    if (contacts.isNotEmpty) {
      for (var contact in contacts) {
        // 如果通讯录中存在，将本地匹配记录放入结果集
        var mobile = contact.mobile;
        var mobileContact = mobileContactMap[mobile];
        if (mobileContact != null) {
          mobileContactMap.remove(mobile);
          lastContacts.add(contact);
        } else {
          // 如果通讯录不存在，则本地库删除
          await delete(entity: contact);
        }
      }
    }
    // 通讯录中剩余的记录，新增的记录将被检查好友记录和服务器记录，然后插入本地库并加入结果集
    var leftContacts = mobileContactMap.values;
    for (var leftContact in leftContacts) {
      await insert(leftContact);
      lastContacts.add(leftContact);
    }

    return lastContacts;
  }

  Future<List<Contact>> search(String key) async {
    if (StringUtil.isEmpty(key)) {
      return await findAll();
    }
    var where = 'peerId=? or mobile=? or name=? or pyName=? or email=?';
    var whereArgs = [key, key, key, key, key];
    var contacts = await find(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'pyName',
    );
    return contacts;
  }

  // 从服务器端获取是否有peerClient
  Future<Contact?> refresh(Contact peerContact) async {
    var mobile = peerContact.mobile;
    if (mobile != null) {
      var mobileNumber = await formatMobile(mobile);
      var peerClient =
          await peerClientService.findOneEffectiveByMobile(mobileNumber);
      if (peerClient != null) {
        peerContact.peerId = peerClient.peerId;
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
    fields: ServiceLocator.buildFields(Contact('', ''), []));
