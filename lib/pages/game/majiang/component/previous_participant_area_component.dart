import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/RoundParticipant.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/round_participant_component.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 上家信息区域
class PreviousParticipantAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.cyanAccent
    ..style = PaintingStyle.fill;

  RoundParticipant? roundParticipant;
  RoundParticipantComponent? roundParticipantComponent;

  PreviousParticipantAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(0),
                MajiangFlameGame.y(MajiangFlameGame.height *
                    MajiangFlameGame.opponentHeightRadio)),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width * MajiangFlameGame.previousWidthRadio,
                MajiangFlameGame.height * MajiangFlameGame.previousHeightRadio),
            paint: fillPaint);

  loadRoundParticipant() {
    if (roundParticipantComponent != null) {
      remove(roundParticipantComponent!);
    }
    if (roundParticipant != null) {
      roundParticipantComponent =
          RoundParticipantComponent(roundParticipant!, 3);
      add(roundParticipantComponent!);
    }
  }

  @override
  Future<void> onLoad() async {}
}
