import 'package:colla_chat/pages/game/majiang/base/outstanding_action.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/base/round_participant.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

/// 等待处理的行为区域
class ActionAreaComponent extends RectangleComponent
    with HasVisibility, HasGameRef<MajiangFlameGame> {
  ActionAreaComponent() {
    _init();
  }

  _init() {
    position = Vector2(
        MajiangFlameGame.x(MajiangFlameGame.width *
            (1 -
                MajiangFlameGame.nextWidthRadio -
                MajiangFlameGame.nextHandWidthRadio -
                MajiangFlameGame.nextWasteWidthRadio)),
        MajiangFlameGame.y(MajiangFlameGame.height *
            (1 -
                MajiangFlameGame.selfHeightRadio -
                MajiangFlameGame.selfWasteHeightRadio)));
    size = Vector2(
        MajiangFlameGame.width *
            (MajiangFlameGame.nextWasteWidthRadio +
                MajiangFlameGame.nextHandWidthRadio),
        MajiangFlameGame.height * MajiangFlameGame.selfHeightRadio);
    paint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.fill;
  }

  loadSpriteButton() {
    RoundParticipant? roundParticipant = roomController
        .getRoundParticipant(roomController.selfParticipantDirection.value);
    Map<OutstandingAction, List<int>>? outstandingActions =
        roundParticipant?.outstandingActions.value;
    if (outstandingActions == null) {
      return;
    }
    double x = 0;
    double y = 0;
    for (var entry in outstandingActions.entries) {
      OutstandingAction outstandingAction = entry.key;

      /// 位置，在明杠，暗杠，吃牌的时候有用
      List<int> pos = entry.value;
      Sprite? sprite = allOutstandingActions[outstandingAction];
      if (sprite != null) {
        Vector2 position = Vector2(x, y);
        Vector2 size = Vector2(
            sprite.image.width.toDouble(), sprite.image.height.toDouble());
        x += sprite.image.width.toDouble();
        SpriteButtonComponent spriteButtonComponent = SpriteButtonComponent(
            button: sprite,
            buttonDown: sprite,
            position: position,
            size: size,
            onPressed: () {
              _call(outstandingAction, pos: pos);
              outstandingActions.clear();
            });
        add(spriteButtonComponent);
      }
    }
  }

  _call(OutstandingAction outstandingAction, {List<int>? pos}) async {
    Room? room = roomController.room.value;
    if (room == null) {
      return;
    }
    int owner = roomController.selfParticipantDirection.value.index;
    Round? round = roomController.currentRound;
    if (round == null) {
      return;
    }
    if (outstandingAction == OutstandingAction.complete) {
      CompleteType? completeType = await room.onRoomEvent(
          RoomEvent(room.name, round.id, owner, RoomEventAction.complete));
      if (completeType != null) {
        room.onRoomEvent(
            RoomEvent(room.name, round.id, owner, RoomEventAction.round));
      }
    } else if (outstandingAction == OutstandingAction.touch) {
      room.onRoomEvent(RoomEvent(
          room.name, round.id, owner, RoomEventAction.touch,
          src: round.sender, card: round.sendCard, pos: pos![0]));
    } else if (outstandingAction == OutstandingAction.bar) {
      room.onRoomEvent(RoomEvent(
          room.name, round.id, owner, RoomEventAction.bar,
          pos: pos![0]));
    } else if (outstandingAction == OutstandingAction.darkBar) {
      room.onRoomEvent(RoomEvent(
          room.name, round.id, owner, RoomEventAction.darkBar,
          pos: pos![0]));
    } else if (outstandingAction == OutstandingAction.pass) {
      room.onRoomEvent(RoomEvent(
          room.name, round.id, owner, RoomEventAction.pass,
          pos: pos![0]));
    } else if (outstandingAction == OutstandingAction.drawing) {
      room.onRoomEvent(RoomEvent(
          room.name, round.id, owner, RoomEventAction.drawing,
          pos: pos![0]));
    }
  }
}
