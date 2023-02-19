import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
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
        width: 32,
        height: 32,
        maxCount: 9,
      );
    }
    conferences[conferenceId] = conference;
  }

  Future<Conference> createConference(
    String name, {
    String? title,
    String? conferenceOwnerPeerId,
    List<String>? participants,
  }) async {
    var old = await findOneByName(name);
    if (old != null) {
      return old;
    }
    var uuid = const Uuid();
    String conferenceId = uuid.v4();
    conferenceOwnerPeerId = conferenceOwnerPeerId ?? myself.peerId;
    var conference = Conference(conferenceId,
        name: name,
        title: title,
        conferenceOwnerPeerId: conferenceOwnerPeerId,
        participants: participants);

    conference.status = EntityStatus.effective.name;

    return conference;
  }

  Future<Conference?> store(Conference conference) async {
    Conference? old = await findOneByConferenceId(conference.conferenceId);
    if (old != null) {
      conference.id = old.id;
      conference.createDate = old.createDate;
    } else {
      conference.id = null;
    }
    await upsert(conference);
    conferences[conference.conferenceId] = conference;

    return conference;
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
    fields: ServiceLocator.buildFields(Conference(''), []));
