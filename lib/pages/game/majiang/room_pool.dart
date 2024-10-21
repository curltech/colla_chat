import 'dart:async';

import 'package:colla_chat/pages/game/majiang/room.dart';
import 'package:colla_chat/tool/json_util.dart';

class MajiangRoomPool {
  final Map<String, MajiangRoom> rooms = {};

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  Future<MajiangRoom> createRoom(String name, List<String> peerIds) async {
    MajiangRoom majiangRoom = MajiangRoom(name);
    await majiangRoom.init(peerIds);
    rooms[name] = majiangRoom;

    return majiangRoom;
  }

  MajiangRoom? get(String name) {
    return rooms[name];
  }

  /// 房间的事件有外部触发，所有订阅者都会触发监听事件，本方法由外部调用，比如外部的消息chatMessage
  onRoomEvent(RoomEvent roomEvent) async {
    String roomName = roomEvent.name;
    MajiangRoom? room = get(roomName);
    if (room == null) {
      return;
    }
    if (roomEvent.action == RoomEventAction.room) {
      List<String>? peerIds;
      String? content = roomEvent.content;
      if (content != null) {
        peerIds = JsonUtil.toJson(content);
      } else {
        peerIds = [];
      }
      createRoom(roomName, peerIds!);
    } else {
      room.onRoomEvent(roomEvent);
    }
  }
}

final MajiangRoomPool majiangRoomPool = MajiangRoomPool();
