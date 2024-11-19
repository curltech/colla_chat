import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/waste_pile.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/waste_pile_component.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// 河牌区域
class WasteAreaComponent extends RectangleComponent
    with TapCallbacks, HasGameRef<MajiangFlameGame> {
  final int direction;

  WastePileComponent? wastePileComponent;

  WasteAreaComponent(this.direction) {
    _init();
  }

  _init() {
    if (direction == 0) {
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
    if (direction == 1) {
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
    if (direction == 2) {
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
    if (direction == 3) {
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
    }
    Room? room = roomController.room.value;
    if (room != null) {
      WastePile? wastePile =
          room.currentRound?.roundParticipants[direction].wastePile;
      if (wastePile != null) {
        wastePileComponent = WastePileComponent(wastePile, direction,
            position: Vector2(10, 10), scale: Vector2(0.85, 0.85));
        add(wastePileComponent!);
      }
    }
  }
}
