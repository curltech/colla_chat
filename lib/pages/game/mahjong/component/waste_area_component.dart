import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/component/waste_pile_component.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// 河牌区域
class WasteAreaComponent extends RectangleComponent
    with TapCallbacks, HasGameRef<MahjongFlameGame> {
  final AreaDirection areaDirection;

  WastePileComponent? wastePileComponent;

  TextBoxComponent? textComponent;

  WasteAreaComponent(this.areaDirection) {
    _init();
  }

  _init() {
    if (areaDirection == AreaDirection.self) {
      position = Vector2(
          roomController.x(roomController.width *
              (MahjongFlameGame.previousWidthRadio +
                  MahjongFlameGame.previousHandWidthRadio +
                  MahjongFlameGame.previousWasteWidthRadio)),
          roomController.y(roomController.height *
              (1 -
                  MahjongFlameGame.selfHeightRadio -
                  MahjongFlameGame.selfWasteHeightRadio)));
      size = Vector2(
          roomController.width * MahjongFlameGame.selfWasteWidthRadio,
          roomController.height * MahjongFlameGame.selfWasteHeightRadio);
      paint = Paint()
        ..color = Colors.pinkAccent
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.next) {
      position = Vector2(
          roomController.x(roomController.width *
              (1 -
                  MahjongFlameGame.nextWidthRadio -
                  MahjongFlameGame.nextHandWidthRadio -
                  MahjongFlameGame.nextWasteWidthRadio)),
          roomController.y(
              roomController.height * MahjongFlameGame.opponentHeightRadio));
      size = Vector2(
          roomController.width * MahjongFlameGame.nextWasteWidthRadio,
          roomController.height * MahjongFlameGame.nextHeightRadio);
      paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.opponent) {
      position = Vector2(
          roomController.x(roomController.width *
              (MahjongFlameGame.previousWidthRadio +
                  MahjongFlameGame.previousHandWidthRadio +
                  MahjongFlameGame.previousWasteWidthRadio)),
          roomController.y(
              roomController.height * MahjongFlameGame.opponentHeightRadio));
      size = Vector2(
          roomController.width * MahjongFlameGame.opponentWasteWidthRadio,
          roomController.height * MahjongFlameGame.opponentWasteHeightRadio);
      paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.previous) {
      position = Vector2(
          roomController.x(roomController.width *
              (MahjongFlameGame.previousWidthRadio +
                  MahjongFlameGame.previousHandWidthRadio)),
          roomController.y(
              roomController.height * MahjongFlameGame.opponentHeightRadio));
      size = Vector2(
          roomController.width * MahjongFlameGame.previousWasteWidthRadio,
          roomController.height * MahjongFlameGame.previousHeightRadio);
      paint = Paint()
        ..color = Colors.indigoAccent
        ..style = PaintingStyle.fill;
    }
  }

  loadWastePile() {
    if (wastePileComponent != null) {
      remove(wastePileComponent!);
      wastePileComponent = null;
    }
    if (textComponent != null) {
      remove(textComponent!);
      textComponent = null;
    }
    Room? room = roomController.room.value;
    if (room != null) {
      if (areaDirection == AreaDirection.previous ||
          areaDirection == AreaDirection.next) {
        wastePileComponent =
            WastePileComponent(areaDirection, scale: Vector2(1, 1));
      }
      if (areaDirection == AreaDirection.self ||
          areaDirection == AreaDirection.opponent) {
        wastePileComponent =
            WastePileComponent(areaDirection, scale: Vector2(0.85, 0.85));
      }
      add(wastePileComponent!);

      // String? name = roomController.getParticipantDirection(areaDirection).name;
      // TextPaint textPaint = TextPaint(
      //   style: const TextStyle(
      //     color: Colors.black,
      //     fontSize: 20.0,
      //   ),
      // );
      // textComponent = TextBoxComponent(
      //     text: name,
      //     align: Anchor.center,
      //     textRenderer: textPaint,
      //     position: Vector2(0, 32),priority: 1);
      // add(textComponent!);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    Round? round = roomController.currentRound;
    if (round == null) {
      return;
    }

    if (round.total != 136) {
      logger.e('round total error:${round.total}');
    }
    roomController.selfParticipantDirection.value =
        roomController.getParticipantDirection(areaDirection);
    game.reload();
  }
}
