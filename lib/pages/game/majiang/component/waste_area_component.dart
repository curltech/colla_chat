import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/waste_pile_component.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// 河牌区域
class WasteAreaComponent extends RectangleComponent
    with TapCallbacks, HasGameRef<MajiangFlameGame> {
  final AreaDirection areaDirection;

  WastePileComponent? wastePileComponent;

  TextBoxComponent? textComponent;

  WasteAreaComponent(this.areaDirection) {
    _init();
  }

  _init() {
    if (areaDirection == AreaDirection.self) {
      position = Vector2(
          MajiangFlameGame.x(MajiangFlameGame.width *
              (MajiangFlameGame.previousWidthRadio +
                  MajiangFlameGame.previousHandWidthRadio +
                  MajiangFlameGame.previousWasteWidthRadio)),
          MajiangFlameGame.y(MajiangFlameGame.height *
              (1 -
                  MajiangFlameGame.selfHeightRadio -
                  MajiangFlameGame.selfWasteHeightRadio)));
      size = Vector2(
          MajiangFlameGame.width * MajiangFlameGame.selfWasteWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.selfWasteHeightRadio);
      paint = Paint()
        ..color = Colors.pinkAccent
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.next) {
      position = Vector2(
          MajiangFlameGame.x(MajiangFlameGame.width *
              (1 -
                  MajiangFlameGame.nextWidthRadio -
                  MajiangFlameGame.nextHandWidthRadio -
                  MajiangFlameGame.nextWasteWidthRadio)),
          MajiangFlameGame.y(
              MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio));
      size = Vector2(
          MajiangFlameGame.width * MajiangFlameGame.nextWasteWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.nextHeightRadio);
      paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.opponent) {
      position = Vector2(
          MajiangFlameGame.x(MajiangFlameGame.width *
              (MajiangFlameGame.previousWidthRadio +
                  MajiangFlameGame.previousHandWidthRadio +
                  MajiangFlameGame.previousWasteWidthRadio)),
          MajiangFlameGame.y(
              MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio));
      size = Vector2(
          MajiangFlameGame.width * MajiangFlameGame.opponentWasteWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.opponentWasteHeightRadio);
      paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.previous) {
      position = Vector2(
          MajiangFlameGame.x(MajiangFlameGame.width *
              (MajiangFlameGame.previousWidthRadio +
                  MajiangFlameGame.previousHandWidthRadio)),
          MajiangFlameGame.y(
              MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio));
      size = Vector2(
          MajiangFlameGame.width * MajiangFlameGame.previousWasteWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.previousHeightRadio);
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
      wastePileComponent =
          WastePileComponent(areaDirection, scale: Vector2(0.85, 0.85));
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
    roomController.selfParticipantDirection.value =
        roomController.getParticipantDirection(areaDirection);
  }
}
