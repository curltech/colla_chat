import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';

class Conference extends StatusEntity {
  String conferenceId; // 会议编号，也是房间号，也是邀请消息号
  String name;
  String? topic;
  String? conferenceOwnerPeerId; // 发起人
  String? groupPeerId; // 如果是从群中发起的会议，设置为群的编号
  String? groupName;
  String? groupType;
  String? password; // 密码
  bool linkman = false; // 是否好友才能参加
  bool contact = false; // 是否在地址本才能参加
  String? startDate; // 开始时间
  String? endDate; // 结束时间
  bool notification = true; // 自动发送会议通知
  bool mute = false; // 自动静音
  bool video = true; // 是否视频
  bool wait = true; // 自动等待
  bool advance = true; // 参会者可提前加入
  int upperNumber = 300; // 参会人数上限
  List<String>? participants; // 参与人peerId的集合
  Widget? avatarImage; //类似群的图标，几个参加者的图标的混合

  Conference(this.conferenceId,
      {required this.name,
      this.conferenceOwnerPeerId,
      this.topic,
      this.startDate,
      this.endDate,
      this.video = true,
      this.groupPeerId,
      this.groupName,
      this.groupType,
      this.participants = const <String>[]});

  Conference.fromJson(Map json)
      : conferenceId = json['conferenceId'],
        name = json['name'],
        topic = json['topic'],
        conferenceOwnerPeerId = json['conferenceOwnerPeerId'],
        groupPeerId = json['groupPeerId'],
        groupName = json['groupName'],
        groupType = json['groupType'],
        password = json['password'],
        startDate = json['startDate'],
        endDate = json['endDate'],
        linkman =
            json['linkman'] == true || json['linkman'] == 1 ? true : false,
        contact =
            json['contact'] == true || json['contact'] == 1 ? true : false,
        notification = json['notification'] == true || json['notification'] == 1
            ? true
            : false,
        mute = json['mute'] == true || json['mute'] == 1 ? true : false,
        video = json['video'] == true || json['video'] == 1 ? true : false,
        wait = json['wait'] == true || json['wait'] == 1 ? true : false,
        advance =
            json['advance'] == true || json['advance'] == 1 ? true : false,
        upperNumber = json['upperNumber'] ?? 300,
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
      'groupPeerId': groupPeerId,
      'groupName': groupName,
      'groupType': groupType,
      'password': password,
      'startDate': startDate,
      'endDate': endDate,
      'linkman': linkman,
      'contact': contact,
      'notification': notification,
      'mute': mute,
      'advance': advance,
      'video': video,
      'upperNumber': upperNumber,
      'participants':
          participants == null ? null : JsonUtil.toJsonString(participants),
    });
    return json;
  }
}
