import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/json_util.dart';

class RoomPool {
  final Map<String, Room> rooms = {};

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  /// 根据房间名称和参与者的编号创建房间
  /// 用于按钮的调用
  Future<Room> createRoom(String name, List<String> peerIds) async {
    Room room = Room(name, peerIds: peerIds);
    await room.init();
    rooms[name] = room;

    return room;
  }

  Room? get(String name) {
    return rooms[name];
  }

  /// 房间的事件有外部触发，所有订阅者都会触发监听事件，
  /// 本方法由外部调用，比如外部的消息chatMessage
  onRoomEvent(ChatMessage chatMessage) async {
    String json = chatMessageService.recoverContent(chatMessage.content!);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    RoomEvent roomEvent = RoomEvent.fromJson(map);

    if (roomEvent.action == RoomEventAction.room) {
      String? content = roomEvent.content;
      if (content != null) {
        var json = JsonUtil.toJson(content);
        Room room = Room.fromJson(json);
        await room.init();
      }
    } else {
      String roomName = roomEvent.name;
      Room? room = get(roomName);
      if (room == null) {
        return;
      }
      room.onRoomEvent(roomEvent);
    }
  }
}

final RoomPool roomPool = RoomPool();
