import 'package:colla_chat/pages/game/mahjong/base/outstanding_action.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

/// 等待处理的行为区域
class ActionAreaComponent extends RectangleComponent
    with HasGameRef<MahjongFlameGame> {
  ActionAreaComponent() {
    _init();
  }

  _init() {
    priority = 10;
    position = Vector2(
        roomController.x(roomController.width *
            (1 -
                MahjongFlameGame.nextWidthRadio -
                MahjongFlameGame.nextHandWidthRadio -
                MahjongFlameGame.nextWasteWidthRadio)),
        roomController.y(roomController.height *
                (1 -
                    MahjongFlameGame.selfHeightRadio -
                    MahjongFlameGame.selfWasteHeightRadio) +
            90));
    size = Vector2(
        roomController.width *
            (MahjongFlameGame.nextWasteWidthRadio +
                MahjongFlameGame.nextHandWidthRadio +
                MahjongFlameGame.nextWidthRadio),
        roomController.height * MahjongFlameGame.selfHeightRadio * 0.7);
    paint = Paint()
      ..color = Colors.white.withAlpha(0)
      ..style = PaintingStyle.fill;
  }

  loadSpriteButton() {
    RoundParticipant? roundParticipant = roomController
        .getRoundParticipant(roomController.selfParticipantDirection.value);
    Map<MahjongAction, Set<int>>? outstandingActions =
        roundParticipant?.outstandingActions.value;
    if (outstandingActions == null || outstandingActions.isEmpty) {
      return;
    }
    outstandingActions[MahjongAction.pass] = {};
    double x = 0;
    double y = 0;
    for (var entry in outstandingActions.entries) {
      MahjongAction outstandingAction = entry.key;

      /// 位置，在明杠，暗杠，吃牌的时候有用
      Set<int> pos = entry.value;
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
              _call(outstandingAction, pos.toList());
              outstandingActions.clear();
              game.loadActionArea();
            });
        add(spriteButtonComponent);
      }
    }
  }

  _call(MahjongAction outstandingAction, List<int> pos) {
    Room? room = roomController.room.value;
    if (room == null) {
      return;
    }
    int owner = roomController.selfParticipantDirection.value.index;
    Round? round = roomController.currentRound;
    if (round == null) {
      return;
    }

    if (outstandingAction == MahjongAction.win) {
      room.startRoomEvent(RoomEvent(room.name,
          roundId: round.id,
          owner: owner,
          action: RoomEventAction.win,
          pos: pos[0]));
    } else if (outstandingAction == MahjongAction.touch) {
      room.startRoomEvent(RoomEvent(room.name,
          roundId: round.id,
          owner: owner,
          action: RoomEventAction.touch,
          src: round.discardParticipant,
          tile: round.discardTile,
          pos: pos[0]));
    } else if (outstandingAction == MahjongAction.bar) {
      room.startRoomEvent(RoomEvent(room.name,
          roundId: round.id,
          owner: owner,
          action: RoomEventAction.bar,
          pos: pos[0]));
    } else if (outstandingAction == MahjongAction.darkBar) {
      room.startRoomEvent(RoomEvent(room.name,
          roundId: round.id,
          owner: owner,
          action: RoomEventAction.darkBar,
          pos: pos[0]));
    } else if (outstandingAction == MahjongAction.pass) {
      room.startRoomEvent(RoomEvent(room.name,
          roundId: round.id, owner: owner, action: RoomEventAction.pass));
    } else if (outstandingAction == MahjongAction.chow) {
      room.startRoomEvent(RoomEvent(room.name,
          roundId: round.id,
          owner: owner,
          action: RoomEventAction.chow,
          pos: pos[0]));
    }
  }
}
