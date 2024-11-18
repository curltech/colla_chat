import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/RoundParticipant.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/round_participant_component.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 下家的信息区域
class NextParticipantAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.cyan
    ..style = PaintingStyle.fill;

  RoundParticipant? roundParticipant;
  RoundParticipantComponent? roundParticipantComponent;

  NextParticipantAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(MajiangFlameGame.width *
                    (1 - MajiangFlameGame.nextWidthRadio)),
                MajiangFlameGame.y(MajiangFlameGame.height *
                    MajiangFlameGame.opponentHeightRadio)),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width * MajiangFlameGame.nextWidthRadio,
                MajiangFlameGame.height * MajiangFlameGame.nextHeightRadio),
            paint: fillPaint);

  loadRoundParticipant() {
    if (roundParticipantComponent != null) {
      remove(roundParticipantComponent!);
    }
    if (roundParticipant != null) {
      roundParticipantComponent =
          RoundParticipantComponent(roundParticipant!, 1);
      add(roundParticipantComponent!);
    }
  }

  @override
  Future<void> onLoad() async {}
}
