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
    if (StringUtil.isEmpty(key)) {
      return await findAll();
    }
    var where = 'conferenceOwnerPeerId=? or name like ? or title like ?';
    var whereArgs = [key, keyword, keyword];
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
        height: AppIconSize.lgSize.height,
        width: AppIconSize.lgSize.width,
        maxCount: 9,
      );
    }
    conferences[conferenceId] = conference;
  }

  Future<Conference> createConference(
    String name, {
    String? topic,
    String? conferenceOwnerPeerId,
    String? groupPeerId,
    String? groupName,
    String? groupType,
    String? startDate,
    String? endDate,
    bool video = true,
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
        .add(const Duration(minutes: 60))
        .toIso8601String();
    var conference = Conference(conferenceId,
        name: name,
        topic: topic,
        conferenceOwnerPeerId: conferenceOwnerPeerId,
        groupPeerId: groupPeerId,
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
  Future<List<Object>> store(Conference conference) async {
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
      return [conference, [], []];
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
    for (var memberPeerId in participants) {
      var member = oldMembers[memberPeerId];
      if (member == null) {
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(memberPeerId);
        if (linkman != null) {
          GroupMember groupMember = GroupMember(conferenceId, memberPeerId);
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
          groupMember.status = EntityStatus.effective.name;
          await groupMemberService.store(groupMember);
          newMembers.add(groupMember);
        }
      } else {
        oldMembers.remove(memberPeerId);
      }
    }

    //处理删除的成员
    if (oldMembers.isNotEmpty) {
      for (GroupMember member in oldMembers.values) {
        await groupMemberService.delete(entity: {'id': member.id});
      }
    }
    conferences[conference.conferenceId] = conference;
    await chatSummaryService.upsertByConference(conference);

    return [conference, newMembers, oldMembers.values.toList()];
  }

  removeByConferenceId(String conferenceId) async {
    await delete(where: 'conferenceId=?', whereArgs: [conferenceId]);
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
      'title'
    ],
    fields: ServiceLocator.buildFields(Conference('', name: ''), []));
