import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';

class Conference extends StatusEntity {
  String conferenceId; // 会议编号，也是房间号，也是邀请消息号
  String name;
  String? topic;
  String? conferenceOwnerPeerId; // 发起人
  String? conferenceOwnerName; // 发起人
  String? groupId; // 如果是从群中发起的会议，设置为群的编号
  String? groupName;
  String? groupType;
  String? password; // 加密密码
  String? startDate; // 开始时间
  String? endDate; // 结束时间
  bool adaptiveStream = true; // 自动适配流
  bool dynacast = false; //
  bool simulcast = true; //
  bool fastConnect = false; //
  bool video = true; // 是否视频
  bool e2ee = false; // 加密
  int maxParticipants = 0; // 参会人数上限
  bool sfu = true;
  String? sfuUri;
  String? sfuToken;
  List<String>? participants; // 参与人peerId的集合
  Widget? avatarImage; //类似群的图标，几个参加者的图标的混合

  Conference(this.conferenceId,
      {required this.name,
      this.conferenceOwnerPeerId,
      this.topic,
      this.startDate,
      this.endDate,
      this.video = true,
      this.groupId,
      this.groupName,
      this.groupType,
      this.participants = const <String>[]});

  Conference.fromJson(Map json)
      : conferenceId = json['conferenceId'],
        name = json['name'],
        topic = json['topic'],
        conferenceOwnerPeerId = json['conferenceOwnerPeerId'],
        conferenceOwnerName = json['conferenceOwnerName'],
        groupId = json['groupId'],
        groupName = json['groupName'],
        groupType = json['groupType'],
        password = json['password'],
        startDate = json['startDate'],
        endDate = json['endDate'],
        adaptiveStream =
            json['adaptiveStream'] == true || json['adaptiveStream'] == 1
                ? true
                : false,
        dynacast =
            json['dynacast'] == true || json['dynacast'] == 1 ? true : false,
        simulcast =
            json['simulcast'] == true || json['simulcast'] == 1 ? true : false,
        fastConnect = json['fastConnect'] == true || json['fastConnect'] == 1
            ? true
            : false,
        video = json['video'] == true || json['video'] == 1 ? true : false,
        e2ee = json['e2ee'] == true || json['e2ee'] == 1 ? true : false,
        maxParticipants = json['maxParticipants'] ?? 0,
        sfu = json['sfu'] == true || json['sfu'] == 1 ? true : false,
        sfuUri = json['sfuUri'],
        sfuToken = json['sfuToken'],
        super.fromJson(json) {
    var participants = json['participants'] != null
        ? JsonUtil.toJson(json['participants'])
        : null;
    if (participants != null && participants is List) {
      this.participants = <String>[];
      for (var participant in participants) {
        this.participants!.add(participant.toString());
      }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'conferenceId': conferenceId,
      'name': name,
      'topic': topic,
      'conferenceOwnerPeerId': conferenceOwnerPeerId,
      'conferenceOwnerName': conferenceOwnerName,
      'groupId': groupId,
      'groupName': groupName,
      'groupType': groupType,
      'password': password,
      'startDate': startDate,
      'endDate': endDate,
      'adaptiveStream': adaptiveStream,
      'dynacast': dynacast,
      'simulcast': simulcast,
      'fastConnect': fastConnect,
      'e2ee': e2ee,
      'video': video,
      'maxParticipants': maxParticipants,
      'sfu': sfu,
      'sfuUri': sfuUri,
      'sfuToken': sfuToken,
      'participants':
          participants == null ? null : JsonUtil.toJsonString(participants),
    });
    return json;
  }
}

class ConferenceChange {
  Conference? conference;
  List<GroupMember>? addGroupMembers;
  List<GroupMember>? removeGroupMembers;
  List<String>? unknownPeerIds;

  ConferenceChange(
      {this.conference,
      this.addGroupMembers,
      this.removeGroupMembers,
      this.unknownPeerIds});

  ConferenceChange.fromJson(Map json) {
    if (json['conference'] != null) {
      conference = Conference.fromJson(json['conference']);
    }
    if (json['addGroupMembers'] != null) {
      addGroupMembers = <GroupMember>[];
      for (var json in json['addGroupMembers']) {
        var groupMember = GroupMember.fromJson(json);
        addGroupMembers!.add(groupMember);
      }
    }
    if (json['removeGroupMembers'] != null) {
      removeGroupMembers = <GroupMember>[];
      for (var json in json['removeGroupMembers']) {
        var groupMember = GroupMember.fromJson(json);
        removeGroupMembers!.add(groupMember);
      }
    }
    if (json['unknownPeerIds'] != null) {
      unknownPeerIds = JsonUtil.toJson(json['unknownPeerIds']);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'conference': conference?.toJson(),
      'addGroupMembers': JsonUtil.toJson(addGroupMembers),
      'removeGroupMembers': JsonUtil.toJson(removeGroupMembers),
      'unknownPeerIds': JsonUtil.toJson(unknownPeerIds),
    };
  }
}
