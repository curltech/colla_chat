import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum OutstandingAction { pass, touch, bar, darkBar, drawing, complete }

/// 参与者
class Participant {
  final String peerId;

  final String name;

  Widget? avatarWidget;

  ///是否是机器人
  final bool robot;

  Room? room;

  //积分
  final RxInt score = 0.obs;

  /// 记录重要的事件
  final List<RoomEvent> roomEvents = [];

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  Participant(
    this.peerId,
    this.name, {
    this.room,
    this.robot = false,
  }) {
    roomEventStreamSubscription =
        roomEventStreamController.stream.listen((RoomEvent roomEvent) {
      // onRoomEvent(roomEvent);
    });
  }

  Participant.fromJson(Map json)
      : peerId = json['peerId'] == '' ? null : json['id'],
        name = json['name'],
        robot = json['robot'] == true || json['robot'] == 1 ? true : false;

  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'name': name,
      'robot': robot,
    };
  }
}