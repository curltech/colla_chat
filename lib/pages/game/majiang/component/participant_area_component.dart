import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/RoundParticipant.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/round_participant_component.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 信息区域
class ParticipantAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  final int direction;

  RoundParticipantComponent? roundParticipantComponent;

  ParticipantAreaComponent(this.direction) {
    _init();
  }

  _init() {
    if (direction == 0) {
      position = Vector2(
          MajiangFlameGame.x(0),
          MajiangFlameGame.y(MajiangFlameGame.height *
              (1 - MajiangFlameGame.selfHeightRadio)));
      size = Vector2(MajiangFlameGame.width * MajiangFlameGame.selfWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.selfHeightRadio);
      paint = Paint()
        ..color = Colors.lightGreen
        ..style = PaintingStyle.fill;
    }
    if (direction == 1) {
      position = Vector2(
          MajiangFlameGame.x(
              MajiangFlameGame.width * (1 - MajiangFlameGame.nextWidthRadio)),
          MajiangFlameGame.y(
              MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio));
      size = Vector2(MajiangFlameGame.width * MajiangFlameGame.nextWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.nextHeightRadio);
      paint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.fill;
    }
    if (direction == 2) {
      position = Vector2(MajiangFlameGame.x(0), MajiangFlameGame.y(0));
      size = Vector2(
          MajiangFlameGame.width * MajiangFlameGame.opponentWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio);
      paint = Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.fill;
    }
    if (direction == 3) {
      position = Vector2(
          MajiangFlameGame.x(0),
          MajiangFlameGame.y(
              MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio));
      size = Vector2(
          MajiangFlameGame.width * MajiangFlameGame.previousWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.previousHeightRadio);
      paint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.fill;
    }
  }

  loadRoundParticipant() {
    if (roundParticipantComponent != null) {
      remove(roundParticipantComponent!);
    }
    Room? room = roomController.room.value;
    if (room != null) {
      RoundParticipant? roundParticipant =
          room.currentRound?.roundParticipants[direction];
      if (roundParticipant != null) {
        roundParticipantComponent =
            RoundParticipantComponent(roundParticipant, 1);
        add(roundParticipantComponent!);
      }
    }
  }
}
