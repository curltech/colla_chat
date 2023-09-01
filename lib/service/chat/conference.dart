import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/combine_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ConferenceService extends GeneralBaseService<Conference> {
  Map<String, Conference> conferences = {};

  ConferenceService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const ['content', 'thumbnail'],
  }) {
    post = (Map map) {
      return Conference.fromJson(map);
    };
  }

  Future<Conference?> findOneByConferenceId(String conferenceId) async {
    var where = 'conferenceId = ?';
    var whereArgs = [conferenceId];

    var conference = await findOne(where: where, whereArgs: whereArgs);

    return conference;
  }

  Future<Conference?> findOneByName(String name) async {
    var where = 'name = ?';
    var whereArgs = [name];

    var conference = await findOne(where: where, whereArgs: whereArgs);

    return conference;
  }

  Future<Conference?> findCachedOneByConferenceId(String conferenceId) async {
    if (conferences.containsKey(conferenceId)) {
      return conferences[conferenceId];
    }
    Conference? conference = await findOneByConferenceId(conferenceId);

    return conference;
  }

  Future<List<Conference>> search(String key) async {
    var keyword = '%$key%';
    var where = '1=1';
    List<Object> whereArgs = [];
    if (StringUtil.isNotEmpty(key)) {
      where =
          '$where and conferenceOwnerPeerId=? or name like ? or title like ?';
      whereArgs.addAll([key, keyword, keyword]);
    }
    var conferences = await find(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'startDate desc',
    );
    if (conferences.isNotEmpty) {
      for (var conference in conferences) {
        setAvatar(conference);
      }
    }

    return conferences;
  }

  Future<void> setAvatar(Conference conference) async {
    String conferenceId = conference.conferenceId;
    List<GroupMember> members =
        await groupMemberService.findByGroupId(conferenceId);
    List<Linkman> linkmen = await groupMemberService.findLinkmen(members);
    if (linkmen.isNotEmpty) {
      List<Widget> widgets = [];
      for (var linkman in linkmen) {
        if (linkman.avatarImage != null) {
          widgets.add(linkman.avatarImage!);
        }
      }
      conference.avatarImage = CombineGridView(
        widgets: widgets,
        height: AppIconSize.lgSize,
        width: AppIconSize.lgSize,
        maxCount: 9,
      );
    }
    conferences[conferenceId] = conference;
  }

  Future<Conference> createConference(
    String name,
    bool video, {
    String? topic,
    String? conferenceOwnerPeerId,
    String? groupId,
    String? groupName,
    String? groupType,
    String? startDate,
    String? endDate,
    List<String>? participants,
  }) async {
    //不允许创建同名的会议
    var old = await findOneByName(name);
    if (old != null) {
      return old;
    }
    var uuid = const Uuid();
    String conferenceId = uuid.v4();
    conferenceOwnerPeerId = conferenceOwnerPeerId ?? myself.peerId;
    startDate ??= DateUtil.currentDate();
    endDate ??= DateUtil.currentDateTime()
        .add(const Duration(minutes: 240))
        .toIso8601String();
    var conference = Conference(conferenceId,
        name: name,
        topic: topic,
        conferenceOwnerPeerId: conferenceOwnerPeerId,
        groupId: groupId,
        groupName: groupName,
        groupType: groupType,
        startDate: startDate,
        endDate: endDate,
        video: video,
        participants: participants);

    conference.status = EntityStatus.effective.name;

    return conference;
  }

  ///保存会议以及成员，成员根据participants,conferenceOwnerPeerId决定成员表的身份
  Future<ConferenceChange> store(Conference conference) async {
    Conference? old = await findOneByConferenceId(conference.conferenceId);
    if (old != null) {
      conference.id = old.id;
      conference.createDate = old.createDate;
    } else {
      conference.id = null;
    }
    await upsert(conference);
    var conferenceId = conference.conferenceId;
    var participants = conference.participants;
    if (participants == null || participants.isEmpty) {
      return ConferenceChange(
          conference: conference, addGroupMembers: [], removeGroupMembers: []);
    }
    List<GroupMember> members =
        await groupMemberService.findByGroupId(conferenceId);
    Map<String, GroupMember> oldMembers = {};
    //所有的现有成员
    if (members.isNotEmpty) {
      for (GroupMember member in members) {
        oldMembers[member.memberPeerId!] = member;
      }
    }
    //新增加的成员
    List<GroupMember> newMembers = [];
    List<String> unknownPeerIds = [];
    for (var memberPeerId in participants) {
      var member = oldMembers[memberPeerId];
      if (member == null) {
        GroupMember groupMember = GroupMember(conferenceId, memberPeerId);
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(memberPeerId);
        if (linkman != null) {
          if (linkman.peerId == conference.conferenceOwnerPeerId) {
            groupMember.memberType = MemberType.owner.name;
          } else {
            groupMember.memberType = MemberType.member.name;
          }
          if (StringUtil.isEmpty(linkman.alias)) {
            groupMember.memberAlias = linkman.name;
          } else {
            groupMember.memberAlias = linkman.alias;
          }
          if (linkman.publicKey == null) {
            unknownPeerIds.add(memberPeerId);
          }
        } else {
          unknownPeerIds.add(memberPeerId);
        }
        groupMember.status = EntityStatus.effective.name;
        await groupMemberService.store(groupMember);
        newMembers.add(groupMember);
      } else {
        oldMembers.remove(memberPeerId);
      }
    }

    //处理删除的成员
    if (oldMembers.isNotEmpty) {
      for (GroupMember member in oldMembers.values) {
        groupMemberService.delete(entity: {'id': member.id});
      }
    }
    conferences[conference.conferenceId] = conference;
    await chatSummaryService.upsertByConference(conference);

    return ConferenceChange(
        conference: conference,
        addGroupMembers: newMembers,
        removeGroupMembers: oldMembers.values.toList(),
        unknownPeerIds: unknownPeerIds);
  }

  removeByConferenceId(String conferenceId) async {
    delete(where: 'conferenceId=?', whereArgs: [conferenceId]);
    conferences.remove(conferenceId);
  }
}

final conferenceService = ConferenceService(
    tableName: "chat_conference",
    indexFields: [
      'ownerPeerId',
      'conferenceId',
      'conferenceOwnerPeerId',
      'startDate',
      'name',
      'topic'
    ],
    fields: ServiceLocator.buildFields(Conference('', name: ''), []));
