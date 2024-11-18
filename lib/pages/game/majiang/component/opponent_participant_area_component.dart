import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/RoundParticipant.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/round_participant_component.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 对家的信息区域
class OpponentParticipantAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.redAccent
    ..style = PaintingStyle.fill;

  RoundParticipant? roundParticipant;
  RoundParticipantComponent? roundParticipantComponent;

  OpponentParticipantAreaComponent()
      : super(
            position: Vector2(MajiangFlameGame.x(0), MajiangFlameGame.y(0)),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width * MajiangFlameGame.opponentWidthRadio,
                MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio),
            paint: fillPaint);

  loadRoundParticipant() {
    if (roundParticipantComponent != null) {
      remove(roundParticipantComponent!);
    }
    if (roundParticipant != null) {
      roundParticipantComponent =
          RoundParticipantComponent(roundParticipant!, 2);
      add(roundParticipantComponent!);
    }
  }

  @override
  Future<void> onLoad() async {}
}
