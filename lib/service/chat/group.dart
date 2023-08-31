import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/chat/peer_party.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/combine_grid_view.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

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
      await setAvatar(group);

      List<String> participants =
          await groupMemberService.findPeerIdsByGroupId(group.peerId);
      if (participants.isNotEmpty) {
        group.participants = participants;
      }
    }
    return group;
  }

  Future<void> setAvatar(Group group) async {
    String peerId = group.peerId;
    String? avatar = group.avatar;
    if (avatar != null) {
      var avatarImage = ImageUtil.buildImageWidget(
          image: avatar,
          height: AppIconSize.lgSize,
          width: AppIconSize.lgSize,
          fit: BoxFit.contain);
      group.avatarImage = avatarImage;
    } else {
      List<GroupMember> members =
          await groupMemberService.findByGroupId(peerId);
      List<Linkman> linkmen = await groupMemberService.findLinkmen(members);
      if (linkmen.isNotEmpty) {
        List<Widget> widgets = [];
        for (var linkman in linkmen) {
          if (linkman.avatarImage != null) {
            widgets.add(linkman.avatarImage!);
          } else {
            widgets.add(AppImage.mdAppImage);
          }
        }
        group.avatarImage = CombineGridView(
          widgets: widgets,
          height: AppImageSize.mdSize,
          width: AppImageSize.mdSize,
          maxCount: 9,
        );
      } else {
        group.avatarImage = AppImage.mdAppImage;
      }
    }
    groups[peerId] = group;
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
    group.groupOwnerPeerId = myself.peerId;
    group.groupOwnerName = myself.name;
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

  ///返回数组，内含保存的组，增加的成员和删除的成员
  Future<GroupChange> store(Group group, {bool myAlias = true}) async {
    Group? old = await findOneByPeerId(group.peerId);
    if (old != null) {
      group.id = old.id;
      group.createDate = old.createDate;
      if (!myAlias) {
        group.myAlias = old.myAlias;
      }
    } else {
      group.id = null;
      if (!myAlias) {
        group.myAlias = null;
      }
    }
    await upsert(group);

    List<String>? participants = group.participants;
    if (participants == null) {
      return GroupChange(group: group);
    }
    String groupId = group.peerId;
    List<GroupMember> members = await groupMemberService.findByGroupId(groupId);
    Map<String, GroupMember> oldMembers = {};
    //所有的现有成员
    if (members.isNotEmpty) {
      for (GroupMember member in members) {
        oldMembers[member.memberPeerId!] = member;
      }
    }
    //新增加的成员
    List<GroupMember> newMembers = [];
    for (String participant in participants) {
      var member = oldMembers[participant];
      //成员不存在，创建新的
      if (member == null) {
        GroupMember groupMember = GroupMember(groupId, participant);
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(participant);
        if (linkman != null) {
          if (linkman.peerId == group.groupOwnerPeerId) {
            groupMember.memberType = MemberType.owner.name;
          } else {
            groupMember.memberType = MemberType.member.name;
          }
          if (StringUtil.isEmpty(linkman.alias)) {
            groupMember.memberAlias = linkman.name;
          } else {
            groupMember.memberAlias = linkman.alias;
          }
        } else {
          //加新的联系人，没有名字
          linkman = Linkman(participant, '');
          await linkmanService.insert(linkman);
        }
        groupMember.status = EntityStatus.effective.name;
        await groupMemberService.store(groupMember);
        newMembers.add(groupMember);
      } else {
        oldMembers.remove(participant);
      }
    }
    //处理删除的成员
    if (oldMembers.isNotEmpty) {
      for (GroupMember member in oldMembers.values) {
        groupMemberService.delete(entity: {'id': member.id});
      }
    }
    groups[group.peerId] = group;
    await chatSummaryService.upsertByGroup(group);

    return GroupChange(
        group: group,
        addGroupMembers: newMembers,
        removeGroupMembers: oldMembers.values.toList());
  }

  Future<List<Group>> search(String key) async {
    var keyword = '%$key%';
    var where = '1=1';
    List<Object> whereArgs = [];
    if (StringUtil.isNotEmpty(key)) {
      where =
          '$where and peerId=? or mobile like ? or name like ? or myAlias like ? or email like ?';
      whereArgs.addAll([key, keyword, keyword, keyword, keyword]);
    }
    var groups = await find(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'pyName,name',
    );
    if (groups.isNotEmpty) {
      for (var group in groups) {
        await setAvatar(group);
      }
    }
    return groups;
  }

  ///向联系人发送加群的消息，群成员在group的participants中
  ///发送的目标在peerIds参数中，如果peerIds为空，则在group的participants中
  addGroup(Group group, {List<String>? peerIds}) async {
    Group g = group.copyWithMembers();
    g.myAlias = null;
    ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
      group.peerId,
      PartyType.group,
      content: g.toJsonWithMembers(),
      subMessageType: ChatMessageSubType.addGroup,
    );
    peerIds ??= group.participants;
    await chatMessageService.sendAndStore(
      chatMessage,
      cryptoOption: CryptoOption.group,
      peerIds: peerIds,
    );
  }

  ///接收加群的消息，自动完成加群，发送回执
  receiveAddGroup(ChatMessage chatMessage) async {
    String json = chatMessageService.recoverContent(chatMessage.content!);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    Group group = Group.fromJsonWithMembers(map);
    group.id = null;
    await groupService.store(group, myAlias: false);
    ChatMessage? chatReceipt = await chatMessageService.buildLinkmanChatReceipt(
        chatMessage, MessageReceiptType.accepted);
    await chatMessageService.updateReceiptType(
        chatMessage, MessageReceiptType.accepted);
    await chatMessageService.sendAndStore(chatReceipt,
        cryptoOption: CryptoOption.linkman);
  }

  bool canModifyGroup(Group group) {
    if (myself.peerId == group.groupOwnerPeerId) {
      return true;
    }
    List<String>? participants = group.participants;
    if (participants != null && participants.isNotEmpty) {
      for (var participant in participants) {
        if (participant == myself.peerId) {
          return true;
        }
      }
    }
    logger.e('Not group owner or myself, can not modify group');
    return false;
  }

  ///向群成员发送群属性变化的消息
  modifyGroup(Group group, {List<String>? peerIds}) async {
    if (!canModifyGroup(group)) {
      return;
    }
    Group g = group.copy();
    g.myAlias = null;
    ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
      group.peerId,
      PartyType.group,
      content: g,
      subMessageType: ChatMessageSubType.modifyGroup,
    );
    peerIds ??= group.participants;
    await chatMessageService.sendAndStore(
      chatMessage,
      cryptoOption: CryptoOption.group,
      peerIds: peerIds,
    );
  }

  ///接收变群的消息，完成变群，发送回执
  receiveModifyGroup(ChatMessage chatMessage) async {
    String json = chatMessageService.recoverContent(chatMessage.content!);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    Group group = Group.fromJson(map);
    await groupService.store(group, myAlias: false);
    ChatMessage? chatReceipt = await chatMessageService.buildLinkmanChatReceipt(
        chatMessage, MessageReceiptType.accepted);
    await chatMessageService.updateReceiptType(
        chatMessage, MessageReceiptType.accepted);

    await chatMessageService.sendAndStore(chatReceipt,
        cryptoOption: CryptoOption.linkman);
  }

  bool canDismissGroup(Group group) {
    if (myself.peerId != group.groupOwnerPeerId) {
      logger.e('Not group owner, can not modify group');
      return false;
    }
    return true;
  }

  ///向群成员发送散群的消息
  dismissGroup(Group group) async {
    if (!canDismissGroup(group)) {
      return;
    }
    groupMemberService.delete(where: 'groupId=?', whereArgs: [group.peerId]);
    removeByGroupId(group.peerId);
    ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
      group.peerId,
      PartyType.group,
      title: group.peerId,
      content: group.name,
      subMessageType: ChatMessageSubType.dismissGroup,
    );

    await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: CryptoOption.group, peerIds: group.participants);
  }

  receiveDismissGroup(ChatMessage chatMessage) async {
    String peerId = chatMessage.title!;
    Group? group = await groupService.findCachedOneByPeerId(peerId);
    if (group == null) {
      return;
    }
    groupMemberService.delete(entity: {
      'groupId': peerId,
    });
    removeByGroupId(peerId);
    ChatMessage? chatReceipt = await chatMessageService.buildLinkmanChatReceipt(
        chatMessage, MessageReceiptType.accepted);
    await chatMessageService.updateReceiptType(
        chatMessage, MessageReceiptType.accepted);

    await chatMessageService.sendAndStore(chatReceipt,
        cryptoOption: CryptoOption.linkman);
  }

  ///向群成员发送加群成员的消息，想新增的成员发送加群消息
  addGroupMember(Group group, List<GroupMember> groupMembers,
      {List<String>? peerIds}) async {
    peerIds ??= [];
    if (group.participants != null) {
      peerIds.addAll(group.participants!);
    } else {
      Group? g = await groupService.findCachedOneByPeerId(group.peerId);
      if (g != null && g.participants != null) {
        peerIds.addAll(g.participants!);
      }
    }
    List<String> addPeerIds = [];
    for (var groupMember in groupMembers) {
      addPeerIds.add(groupMember.memberPeerId!);
      peerIds.remove(groupMember.memberPeerId!);
    }
    await addGroup(group, peerIds: addPeerIds);

    ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
        group.peerId, PartyType.group,
        content: groupMembers,
        subMessageType: ChatMessageSubType.addGroupMember);

    await chatMessageService.sendAndStore(
      chatMessage,
      cryptoOption: CryptoOption.group,
      peerIds: peerIds,
    );
  }

  receiveAddGroupMember(ChatMessage chatMessage) async {
    String json = chatMessageService.recoverContent(chatMessage.content!);
    List<dynamic> maps = JsonUtil.toJson(json);
    List<String> peerIds = [];
    for (var map in maps) {
      GroupMember groupMember = GroupMember.fromJson(map);
      groupMember.id = null;
      await groupMemberService.store(groupMember, memberAlias: false);

      Linkman? linkman =
          await linkmanService.findCachedOneByPeerId(groupMember.memberPeerId!);
      if (linkman == null) {
        peerIds.add(groupMember.memberPeerId!);
      }
    }
    if (peerIds.isNotEmpty) {
      await linkmanService.findLinkman(chatMessage.senderPeerId!, peerIds,
          clientId: chatMessage.senderClientId);
    }

    ChatMessage? chatReceipt = await chatMessageService.buildLinkmanChatReceipt(
        chatMessage, MessageReceiptType.accepted);
    await chatMessageService.updateReceiptType(
        chatMessage, MessageReceiptType.accepted);

    await chatMessageService.sendAndStore(chatReceipt,
        cryptoOption: CryptoOption.linkman);
  }

  bool canRemoveGroupMember(Group group, List<GroupMember> groupMembers) {
    if (groupMembers.isNotEmpty) {
      for (var groupMember in groupMembers) {
        if (groupMember.memberPeerId == myself.peerId) {
          return true;
        }
      }
    }

    if (myself.peerId == group.groupOwnerPeerId) {
      return true;
    }
    logger.e('Not group owner or myself, can not remove group member');

    return false;
  }

  ///向群成员发送删群成员的消息
  removeGroupMember(Group group, List<GroupMember> groupMembers,
      {List<String>? peerIds}) async {
    if (!canRemoveGroupMember(group, groupMembers)) {
      return;
    }
    ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
      group.peerId,
      PartyType.group,
      content: groupMembers,
      subMessageType: ChatMessageSubType.removeGroupMember,
    );

    peerIds ??= [];
    if (group.participants != null) {
      peerIds.addAll(group.participants!);
    } else {
      Group? g = await groupService.findCachedOneByPeerId(group.peerId);
      if (g != null && g.participants != null) {
        peerIds.addAll(g.participants!);
      }
    }
    for (var groupMember in groupMembers) {
      if (!peerIds.contains(groupMember.memberPeerId)) {
        peerIds.add(groupMember.memberPeerId!);
      }
    }
    await chatMessageService.sendAndStore(
      chatMessage,
      cryptoOption: CryptoOption.group,
      peerIds: peerIds,
    );
  }

  receiveRemoveGroupMember(ChatMessage chatMessage) async {
    String json = chatMessageService.recoverContent(chatMessage.content!);
    List<dynamic> maps = JsonUtil.toJson(json);
    for (var map in maps) {
      GroupMember groupMember = GroupMember.fromJson(map);
      var memberPeerId = groupMember.memberPeerId;
      var groupId = groupMember.groupId;
      if (memberPeerId == myself.peerId) {
        groupMemberService.delete(entity: {
          'groupId': groupId,
        });
        removeByGroupId(groupId!);
        break;
      } else {
        groupMemberService.delete(entity: {
          'memberPeerId': groupMember.memberPeerId,
          'groupId': groupMember.groupId
        });
      }
    }

    ChatMessage? chatReceipt = await chatMessageService.buildLinkmanChatReceipt(
        chatMessage, MessageReceiptType.accepted);
    await chatMessageService.updateReceiptType(
        chatMessage, MessageReceiptType.accepted);

    await chatMessageService.sendAndStore(chatReceipt,
        cryptoOption: CryptoOption.linkman);
  }

  ///向群成员发送群文件的消息
  groupFile(String groupId, List<int> data) async {
    ChatMessage chatMessage = await chatMessageService.buildGroupChatMessage(
      groupId,
      PartyType.group,
      content: data,
      subMessageType: ChatMessageSubType.groupFile,
    );
    List<String>? peerIds;
    Group? group = await groupService.findCachedOneByPeerId(groupId);
    if (group != null) {
      peerIds = group.participants;
    }
    await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: CryptoOption.group, peerIds: peerIds);
  }

  receiveGroupFile(ChatMessage chatMessage) async {
    Uint8List data = CryptoUtil.decodeBase64(chatMessage.content!);

    ChatMessage? chatReceipt = await chatMessageService.buildLinkmanChatReceipt(
        chatMessage, MessageReceiptType.accepted);
    await chatMessageService.updateReceiptType(
        chatMessage, MessageReceiptType.accepted);

    await chatMessageService.sendAndStore(chatReceipt);
  }

  ///删除群
  removeByGroupId(String peerId) {
    delete(where: 'peerId=?', whereArgs: [peerId]);
    groups.remove(peerId);
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

  Future<List<String>> findPeerIdsByGroupId(String groupId) async {
    List<String> peerIds = <String>[];
    List<GroupMember> groupMembers =
        await groupMemberService.findByGroupId(groupId);
    if (groupMembers.isNotEmpty) {
      for (var groupMember in groupMembers) {
        peerIds.add(groupMember.memberPeerId!);
      }
    }
    return peerIds;
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

  Future<void> store(GroupMember groupMember, {bool memberAlias = true}) async {
    GroupMember? old =
        await findOneByGroupId(groupMember.groupId!, groupMember.memberPeerId!);
    if (old != null) {
      groupMember.id = old.id;
      groupMember.createDate = old.createDate;
      if (!memberAlias) {
        groupMember.memberAlias = old.memberAlias;
      }
    } else {
      if (!memberAlias) {
        Linkman? linkman = await linkmanService
            .findCachedOneByPeerId(groupMember.memberPeerId!);
        if (linkman != null) {
          var alias = linkman.alias;
          alias ??= linkman.name;
          groupMember.memberAlias = alias;
        } else {
          groupMember.memberAlias = null;
        }
      }
    }
    await upsert(groupMember);
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
    fields: ServiceLocator.buildFields(GroupMember('', ''), []));
