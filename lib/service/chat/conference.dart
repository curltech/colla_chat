import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/p2p/chain/action/manageroom.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
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

/// 发送命令到服务器进行房间的管理操作的报文
class LiveKitManageRoom {
  //房间管理命令
  String? manageType;

  int? emptyTimeout;

  String? host;

  String? roomName;

  List<String>? identities;

  List<String>? names;

  List<String>? tokens;

  int maxParticipants = 0;

  List<LiveKitParticipant>? participants;

  // 当列出所有的房间的时候返回的房间列表
  List<LiveKitRoom>? rooms;

  LiveKitManageRoom() : super();

  LiveKitManageRoom.fromJson(Map json) {
    manageType = json['manageType'];
    emptyTimeout = json['emptyTimeout'];
    host = json['host'];
    roomName = json['roomName'];
    maxParticipants = json['maxParticipants'] ?? 0;
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
      'maxParticipants': maxParticipants,
      'identities': identities,
      'names': names,
      'tokens': tokens,
    });
    if (participants != null) {
      List<dynamic> participants = [];
      for (var participant in this.participants!) {
        participants.add(JsonUtil.toJson(participant));
      }
      json['participants'] = participants;
    }
    if (rooms != null) {
      List<dynamic> rooms = [];
      for (var room in this.rooms!) {
        rooms.add(JsonUtil.toJson(room));
      }
      json['rooms'] = rooms;
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
      'creation_time': creationTime?.toUtc().toIso8601String(),
      'turn_password': turnPassword,
      'enabled_codes': JsonUtil.toJson(enabledCodecs),
    });
    return json;
  }
}

class LiveKitParticipant {
  String? sid;

  int? joinedAt;

  String? identity;

  String? name;

  int? state;

  int? version;

  List<String>? permission;

  LiveKitParticipant() : super();

  LiveKitParticipant.fromJson(Map json) {
    sid = json['sid'];
    joinedAt = json['joined_at'];
    name = json['name'];
    identity = json['identity'];
    state = json['state'];
    version = json['version'];
    Map? permission = json['permission'];
    if (permission != null) {
      this.permission = [];
      for (var p in permission.keys) {
        this.permission!.add(p.toString());
      }
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'sid': sid,
      'joined_at': joinedAt,
      'name': name,
      'identity': identity,
      'state': state,
      'version': version,
      'permission': JsonUtil.toJson(permission),
    });
    return json;
  }
}

class ConferenceService extends GeneralBaseService<Conference> {
  Map<String, Conference> conferences = {};

  ConferenceService({
    required super.tableName,
    required super.fields,
    super.uniqueFields = const [
      'conferenceId',
    ],
    super.indexFields = const [
      'ownerPeerId',
      'conferenceOwnerPeerId',
      'startDate',
      'name',
      'topic'
    ],
    super.encryptFields = const ['content', 'thumbnail', 'password'],
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
    String conferenceId = StringUtil.uuid();
    conferenceOwnerPeerId = conferenceOwnerPeerId ?? myself.peerId;
    startDate ??= DateUtil.currentDate();
    endDate ??= DateUtil.currentDateTime()
        .add(const Duration(days: 2))
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
    return await lock.synchronized(() async {
      ConferenceChange conferenceChange;
      Conference? old = await findOneByConferenceId(conference.conferenceId);
      if (old != null) {
        conference.id = old.id;
        conference.createDate = old.createDate;
        if (old.sfuToken != null && old.sfuToken!.isNotEmpty) {
          conference.sfuToken = old.sfuToken;
        }
        await update(conference);
      } else {
        conference.id = null;
        await insert(conference);
      }

      var conferenceId = conference.conferenceId;
      var participants = conference.participants;
      if (participants == null || participants.isEmpty) {
        conferenceChange = ConferenceChange(
            conference: conference,
            addGroupMembers: [],
            removeGroupMembers: []);
      } else {
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

        conferenceChange = ConferenceChange(
            conference: conference,
            addGroupMembers: newMembers,
            removeGroupMembers: oldMembers.values.toList(),
            unknownPeerIds: unknownPeerIds);
      }
      conferences[conference.conferenceId] = conference;
      await chatSummaryService.upsertByConference(conference);

      return conferenceChange;
    });
  }

  Future<void> removeByConferenceId(String conferenceId) async {
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

  /// 如果sfu为true，创建sfu的Room，并填充conference的uri，token和password
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
      eDate = sDate.add(const Duration(days: 2));
      endDate = eDate.toUtc().toIso8601String();
      conference.endDate = endDate;
    }
    bool sfu = conference.sfu;
    if (sfu) {
      int i = 0;
      List<String> names = [];
      if (participants != null) {
        for (String participant in participants) {
          if (participant == myself.peerId) {}
          String? name;
          Linkman? linkman =
              await linkmanService.findCachedOneByPeerId(participant);
          if (linkman != null) {
            name = linkman.name;
            names.add(name);
          }
          i++;
        }
      }
      String? sfuUri = conference.sfuUri;
      sfuUri ??= await _getHost();
      conference.sfuUri = sfuUri;
      eDate = DateUtil.toDateTime(endDate);
      DateTime now = DateTime.now();
      Duration emptyTimeout = eDate.difference(now);

      LiveKitManageRoom liveKitManageRoom = await createSfuRoom(
          conference.conferenceId,
          emptyTimeout: emptyTimeout,
          maxParticipants: conference.maxParticipants,
          participants: participants,
          names: names);
      conference.sfuToken = liveKitManageRoom.tokens;
      if (conference.password == null) {
        CryptoGraphy cryptoGraphy = CryptoGraphy();
        conference.password = await cryptoGraphy.getRandomAsciiString();
      }

      return liveKitManageRoom;
    }

    return null;
  }

  Future<LiveKitManageRoom> manageRoom(ManageType manageType,
      {LiveKitManageRoom? liveKitManageRoom}) async {
    Completer<LiveKitManageRoom> completer = Completer<LiveKitManageRoom>();
    StreamSubscription<ChainMessage>? streamSubscription =
        manageRoomAction.responseStreamController.stream.listen(null);
    streamSubscription.onData((ChainMessage chainMessage) {
      LiveKitManageRoom manageRoom;
      if (chainMessage.payload != null) {
        if (chainMessage.payload is LiveKitManageRoom) {
          manageRoom = chainMessage.payload;
          String? type = manageRoom.manageType;
          logger.i('manageRoom response payload:$type');
          if (type == manageType.name) {
            String? name = liveKitManageRoom?.roomName;
            String? roomName = manageRoom.roomName;
            if (name == null || roomName == name) {
              streamSubscription?.cancel();
              streamSubscription = null;
              completer.complete(manageRoom);
            }
          }
        } else {
          logger.e('manageRoom response payload is not LiveKitManageRoom');
          streamSubscription?.cancel();
          streamSubscription = null;
          completer.completeError(chainMessage.payload);
        }
      }
    });
    streamSubscription?.onError((err) {
      logger.e('manageRoom response onError:$err');
      streamSubscription?.cancel();
      streamSubscription = null;
      completer.completeError(err);
    });
    manageRoomAction.manageRoom(manageType,
        liveKitManageRoom: liveKitManageRoom);
    Future.delayed(const Duration(seconds: 30), () {
      if (streamSubscription != null) {
        streamSubscription?.cancel();
        streamSubscription = null;
        completer.completeError('manageRoom response overtime error');
      }
    });

    return completer.future;
  }

  Future<String?> _getHost() async {
    LiveKitManageRoom liveKitManageRoom = await manageRoom(ManageType.get);

    return liveKitManageRoom.host;
  }

  Future<LiveKitManageRoom> createSfuRoom(String roomName,
      {Duration emptyTimeout = const Duration(days: 1),
      int maxParticipants = 0,
      List<String>? participants,
      List<String>? names}) async {
    LiveKitManageRoom liveKitManageRoom = LiveKitManageRoom();
    liveKitManageRoom.roomName = roomName;
    liveKitManageRoom.maxParticipants = maxParticipants;
    liveKitManageRoom.emptyTimeout = emptyTimeout.inSeconds;
    liveKitManageRoom.identities = participants;
    liveKitManageRoom.names = names;
    liveKitManageRoom = await manageRoom(ManageType.create,
        liveKitManageRoom: liveKitManageRoom);

    return liveKitManageRoom;
  }

  Future<bool> deleteRoom(String roomName) async {
    LiveKitManageRoom liveKitManageRoom = LiveKitManageRoom();
    liveKitManageRoom.roomName = roomName;
    liveKitManageRoom = await manageRoom(ManageType.delete,
        liveKitManageRoom: liveKitManageRoom);
    String? name = liveKitManageRoom.roomName;
    if (name == null) {
      return false;
    }
    return name.isNotEmpty;
  }

  Future<LiveKitManageRoom> listSfuRoom() async {
    LiveKitManageRoom liveKitManageRoom = await manageRoom(ManageType.list);

    return liveKitManageRoom;
  }

  Future<List<LiveKitParticipant>?> listSfuParticipants(String roomName) async {
    LiveKitManageRoom liveKitManageRoom = LiveKitManageRoom();
    liveKitManageRoom.roomName = roomName;
    liveKitManageRoom = await manageRoom(ManageType.listParticipants,
        liveKitManageRoom: liveKitManageRoom);

    return liveKitManageRoom.participants;
  }
}

final conferenceService = ConferenceService(
    tableName: "chat_conference",
    fields: ServiceLocator.buildFields(Conference('', name: ''), []));
