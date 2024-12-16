import 'dart:ui';

import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/component/round_participant_component.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 信息区域
class ParticipantAreaComponent extends RectangleComponent
    with HasGameRef<MahjongFlameGame> {
  final AreaDirection areaDirection;

  RoundParticipantComponent? roundParticipantComponent;

  ParticipantAreaComponent(this.areaDirection) {
    _init();
  }

  _init() {
    if (areaDirection == AreaDirection.self) {
      position = Vector2(
          MahjongFlameGame.x(0),
          MahjongFlameGame.y(MahjongFlameGame.height *
              (1 - MahjongFlameGame.selfHeightRadio)));
      size = Vector2(MahjongFlameGame.width * MahjongFlameGame.selfWidthRadio,
          MahjongFlameGame.height * MahjongFlameGame.selfHeightRadio);
      paint = Paint()
        ..color = Colors.lightGreen
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.next) {
      position = Vector2(
          MahjongFlameGame.x(
              MahjongFlameGame.width * (1 - MahjongFlameGame.nextWidthRadio)),
          MahjongFlameGame.y(
              MahjongFlameGame.height * MahjongFlameGame.opponentHeightRadio));
      size = Vector2(MahjongFlameGame.width * MahjongFlameGame.nextWidthRadio,
          MahjongFlameGame.height * MahjongFlameGame.nextHeightRadio);
      paint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.opponent) {
      position = Vector2(MahjongFlameGame.x(0), MahjongFlameGame.y(0));
      size = Vector2(
          MahjongFlameGame.width * MahjongFlameGame.opponentWidthRadio,
          MahjongFlameGame.height * MahjongFlameGame.opponentHeightRadio);
      paint = Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.previous) {
      position = Vector2(
          MahjongFlameGame.x(0),
          MahjongFlameGame.y(
              MahjongFlameGame.height * MahjongFlameGame.opponentHeightRadio));
      size = Vector2(
          MahjongFlameGame.width * MahjongFlameGame.previousWidthRadio,
          MahjongFlameGame.height * MahjongFlameGame.previousHeightRadio);
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
          roomController.findRoundParticipant(areaDirection);
      if (roundParticipant != null) {
        roundParticipantComponent = RoundParticipantComponent(roundParticipant,
            size: Vector2(64, 42),
            position: Vector2(size.x / 2 - 16, size.y / 2 - 30));
        add(roundParticipantComponent!);
      }
    }
  }
}
