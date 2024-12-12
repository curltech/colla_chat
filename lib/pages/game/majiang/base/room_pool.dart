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
  Future<Room> _createRoom(String name, List<String> peerIds) async {
    Room room = Room(name, peerIds: peerIds);
    await room.init();
    rooms[name] = room;

    return room;
  }

  void send(ChatMessage chatMessage) {}

  Room? get(String name) {
    return rooms[name];
  }

  /// 完成后把事件分发到其他参与者
  dynamic startRoomEvent(RoomEvent roomEvent) async {
    if (roomEvent.action == RoomEventAction.room) {
      Room room = await _createRoom(roomEvent.name, roomEvent.content);
      // 将创建房间的命令和数据发送给其他参与者
      // 对机器人直接调用onRoomEvent处理
      // 对正常参与者需要发送chatMessage
      for (int i = 0; i < room.participants.length; ++i) {
        Participant participant = room.participants[i];
        if (participant.peerId != myself.peerId) {
          String content = JsonUtil.toJsonString(room);
          RoomEvent roomEvent = RoomEvent(
              room.name, null, i, RoomEventAction.room,
              content: content);
          ChatMessage chatMessage = await chatMessageService.buildChatMessage(
              receiverPeerId: participant.peerId,
              subMessageType: ChatMessageSubType.majiang,
              content: roomEvent);
          if (participant.robot) {
            onRoomEvent(chatMessage);
          } else {
            send(chatMessage);
          }
        }
      }

      return room;
    }

    return null;
  }

  /// 房间的事件有外部触发，所有订阅者都会触发监听事件，
  /// 本方法由外部调用，比如外部的消息chatMessage
  dynamic onRoomEvent(ChatMessage chatMessage) async {
    String json = chatMessageService.recoverContent(chatMessage.content!);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    RoomEvent roomEvent = RoomEvent.fromJson(map);
    logger.w('room pool has received event:${roomEvent.toString()}');
    dynamic returnValue;
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
        returnValue = room;
      }
    } else {
      String roomName = roomEvent.name;
      Room? room = get(roomName);
      if (room == null) {
        return null;
      }
      returnValue = await room.onRoomEvent(roomEvent);
      roomController.majiangFlameGame.reload();
    }

    return returnValue;
  }
}

final RoomPool roomPool = RoomPool();
