import 'dart:async';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/game/majiang/base/participant.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:get/get.dart';

class RoomPool {
  final RxMap<String, Room> rooms = <String, Room>{}.obs;

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  /// 根据房间名称和参与者的编号创建房间
  /// 用于按钮的调用
  Future<Room> createRoom(String name, List<String> peerIds) async {
    Room room = Room(name, peerIds: peerIds);
    await room.init();
    rooms[name] = room;
    // 将创建房间的命令和数据发送给其他参与者
    // 对机器人直接调用onRoomEvent处理
    // 对正常参与者需要发送chatMessage
    for (int i = 0; i < room.participants.length; ++i) {
      Participant participant = room.participants[i];
      if (participant.peerId != myself.peerId) {
        if (participant.robot) {
          String content = JsonUtil.toJsonString(room);
          RoomEvent roomEvent = RoomEvent(
              room.name, null, i, RoomEventAction.room,
              content: content);
          ChatMessage chatMessage = await chatMessageService.buildChatMessage(
              receiverPeerId: participant.peerId,
              subMessageType: ChatMessageSubType.majiang,
              content: roomEvent);
          onRoomEvent(chatMessage);
        } else {}
      }
    }

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
    logger.w('room pool has received event:${roomEvent.toString()}');
    if (roomEvent.action == RoomEventAction.room) {
      String? content = roomEvent.content;
      if (content != null) {
        var json = JsonUtil.toJson(content);
        Room room = Room.fromJson(json);
        await room.init();
        if (!rooms.containsKey(room.name)) {
          rooms[room.name] = room;
          roomController.room.value = room;
        }
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
