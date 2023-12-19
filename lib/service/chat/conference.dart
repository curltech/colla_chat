import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/action/manageroom.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/combine_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:livekit_server_sdk/src/proto/livekit_models.pb.dart';
import 'package:uuid/uuid.dart';

class LiveKitManageRoom {
  String? manageType;

  int? emptyTimeout;

  String? host;

  String? roomName;

  List<String>? identities;

  List<String>? names;

  List<String>? tokens;

  List<LiveKitParticipant>? participants;

  List<LiveKitRoom>? rooms;

  LiveKitManageRoom() : super();

  LiveKitManageRoom.fromJson(Map json) {
    manageType = json['manageType'];
    emptyTimeout = json['emptyTimeout'];
    host = json['host'];
    roomName = json['roomName'];
    identities = json['identities'] != null
        ? List<String>.from(json['identities'] as List<dynamic>)
        : null;
    names = json['names'] != null
        ? List<String>.from(json['names'] as List<dynamic>)
        : null;
    tokens = json['tokens'] != null
        ? List<String>.from(json['tokens'] as List<dynamic>)
        : null;
    List<dynamic>? participants = json['participants'];
    if (participants != null) {
      List<LiveKitParticipant> liveKitParticipants = [];
      for (dynamic participant in participants) {
        LiveKitParticipant liveKitParticipant =
            LiveKitParticipant.fromJson(participant);
        liveKitParticipants.add(liveKitParticipant);
      }
      this.participants = liveKitParticipants;
    }
    List<dynamic>? rooms = json['rooms'];
    if (rooms != null) {
      List<LiveKitRoom> liveKitRooms = [];
      for (dynamic room in rooms) {
        LiveKitRoom liveKitRoom = LiveKitRoom.fromJson(room);
        liveKitRooms.add(liveKitRoom);
      }
      this.rooms = liveKitRooms;
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'manageType': manageType,
      'emptyTimeout': emptyTimeout,
      'host': host,
      'roomName': roomName,
      'identities': identities,
      'names': names,
      'tokens': tokens,
    });
    if (participants != null) {
      json['participants'] = JsonUtil.toJson(participants);
    }
    if (rooms != null) {
      json['rooms'] = JsonUtil.toJson(rooms);
    }

    return json;
  }
}

class LiveKitRoom {
  String? sid;

  int? emptyTimeout;

  String? name;

  DateTime? creationTime;

  String? turnPassword;

  List<String>? enabledCodecs;

  LiveKitRoom() : super();

  LiveKitRoom.fromJson(Map json) {
    sid = json['sid'];
    emptyTimeout = json['empty_timeout'];
    name = json['name'];
    creationTime = json['creation_time'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['creation_time'] * 1000)
        : null;
    turnPassword = json['turn_password'];
    List<dynamic>? enabledCodecs = json['enabled_codecs'];
    if (enabledCodecs != null) {
      this.enabledCodecs = [];
      for (dynamic enabledCodec in enabledCodecs) {
        this.enabledCodecs!.add(JsonUtil.toJsonString(enabledCodec));
      }
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'sid': sid,
      'empty_timeout': emptyTimeout,
      'name': name,
      'creation_time': creationTime,
      'turn_password': turnPassword,
      'enabled_codes': JsonUtil.toJson(enabledCodecs),
    });
    return json;
  }
}

class LiveKitParticipant {
  String? sid;

  int? emptyTimeout;

  String? name;

  DateTime? creationTime;

  String? turnPassword;

  List<String>? enabledCodes;

  LiveKitParticipant() : super();

  LiveKitParticipant.fromJson(Map json) {
    sid = json['sid'];
    emptyTimeout = json['emptyTimeout'];
    name = json['name'];
    creationTime = json['creationTime'];
    turnPassword = json['turnPassword'];
    enabledCodes = json['enabledCodes'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'sid': sid,
      'emptyTimeout': emptyTimeout,
      'name': name,
      'creationTime': creationTime,
      'turnPassword': turnPassword,
      'enabledCodes': JsonUtil.toJson(enabledCodes),
    });
    return json;
  }
}

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

  /// 创建会议，处理开始和结束时间
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
        .add(const Duration(days: 1))
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

  /// 保存会议以及成员，成员根据participants,conferenceOwnerPeerId决定成员表的身份
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

  bool isValid(Conference conference) {
    if (appDebug) {
      return true;
    }
    String? startDate = conference.startDate;
    String? endDate = conference.endDate;
    bool valid = true;
    DateTime? eDate;
    if (endDate != null) {
      eDate = DateUtil.toDateTime(endDate);
    } else {
      if (startDate != null) {
        DateTime sDate = DateUtil.toDateTime(startDate);
        eDate = sDate.add(const Duration(days: 1));
      }
    }
    if (eDate != null) {
      DateTime now = DateTime.now();
      if (now.isAfter(eDate)) {
        valid = false;
      }
    }

    return valid;
  }

  /// 如果sfu为true，创建sfu的Room
  Future<LiveKitManageRoom?> createRoom(
      Conference conference, List<String>? participants) async {
    String? startDate = conference.startDate;
    if (startDate == null) {
      startDate = DateUtil.currentDate();
      conference.startDate = startDate;
    }
    String? endDate = conference.endDate;
    DateTime? eDate;
    if (endDate == null) {
      DateTime sDate = DateUtil.toDateTime(startDate);
      eDate = sDate.add(const Duration(days: 1));
      endDate = eDate.toUtc().toIso8601String();
      conference.endDate = endDate;
    }
    bool sfu = conference.sfu;
    if (sfu) {
      List<String> names = [];
      if (participants != null) {
        for (String participant in participants) {
          String? name;
          Linkman? linkman =
              await linkmanService.findCachedOneByPeerId(participant);
          if (linkman != null) {
            name = linkman.name;
            names.add(name);
          }
        }
      }
      String? sfuUri = conference.sfuUri;
      sfuUri ??= await _getHost();
      conference.sfuUri = sfuUri;
      eDate = DateUtil.toDateTime(endDate);
      DateTime now = DateTime.now();
      Duration emptyTimeout = eDate.difference(now);

      return await createSfuRoom(conference.conferenceId,
          emptyTimeout: emptyTimeout, participants: participants, names: names);
    }

    return null;
  }

  Future<String?> _getHost() async {
    Completer<String?> completer = Completer<String?>();
    StreamSubscription<ChainMessage> streamSubscription =
        manageRoomAction.responseStreamController.stream.listen(null);
    streamSubscription.onData((ChainMessage chainMessage) {
      LiveKitManageRoom liveKitManageRoom = chainMessage.payload;
      String? manageType = liveKitManageRoom.manageType;
      if (manageType == ManageType.get.name) {
        String? host = liveKitManageRoom.host;
        streamSubscription.cancel();
        completer.complete(host);
      }
    });
    manageRoomAction.manageRoom(ManageType.get);

    return completer.future;
  }

  Future<LiveKitManageRoom> createSfuRoom(String roomName,
      {Duration emptyTimeout = const Duration(days: 1),
      List<String>? participants,
      List<String>? names}) async {
    Completer<LiveKitManageRoom> completer = Completer<LiveKitManageRoom>();
    StreamSubscription<ChainMessage> streamSubscription =
        manageRoomAction.responseStreamController.stream.listen(null);
    streamSubscription.onData((ChainMessage chainMessage) {
      LiveKitManageRoom liveKitManageRoom = chainMessage.payload;
      String? manageType = liveKitManageRoom.manageType;
      if (manageType == ManageType.create.name) {
        String? name = liveKitManageRoom.roomName;
        if (roomName == name) {
          streamSubscription.cancel();
          completer.complete(liveKitManageRoom);
        }
      }
    });
    manageRoomAction.manageRoom(ManageType.create,
        roomName: roomName,
        emptyTimeout: emptyTimeout.inSeconds,
        identities: participants,
        names: names);

    return completer.future;
  }

  Future<LiveKitManageRoom> listSfuRoom() async {
    Completer<LiveKitManageRoom> completer = Completer<LiveKitManageRoom>();
    StreamSubscription<ChainMessage> streamSubscription =
        manageRoomAction.responseStreamController.stream.listen(null);
    streamSubscription.onData((ChainMessage chainMessage) {
      LiveKitManageRoom liveKitManageRoom = chainMessage.payload;
      String? manageType = liveKitManageRoom.manageType;
      if (manageType == ManageType.list.name) {
        streamSubscription.cancel();
        completer.complete(liveKitManageRoom);
      }
    });
    manageRoomAction.manageRoom(ManageType.list);

    return completer.future;
  }

  Future<LiveKitManageRoom> listSfuParticipant(String roomName) async {
    Completer<LiveKitManageRoom> completer = Completer<LiveKitManageRoom>();
    StreamSubscription<ChainMessage> streamSubscription =
        manageRoomAction.responseStreamController.stream.listen(null);
    streamSubscription.onData((ChainMessage chainMessage) {
      LiveKitManageRoom liveKitManageRoom = chainMessage.payload;
      String? manageType = liveKitManageRoom.manageType;
      if (manageType == ManageType.listParticipant.name) {
        if (roomName == liveKitManageRoom.roomName) {
          streamSubscription.cancel();
          completer.complete(liveKitManageRoom);
        }
      }
    });
    manageRoomAction.manageRoom(ManageType.listParticipant, roomName: roomName);

    return completer.future;
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
