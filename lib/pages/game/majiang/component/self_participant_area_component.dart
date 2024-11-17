import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 自己信息区域
class SelfParticipantAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.lightGreen
    ..style = PaintingStyle.fill;

  SelfParticipantAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(0),
                MajiangFlameGame.y(MajiangFlameGame.height *
                    (1 - MajiangFlameGame.selfHeightRadio))),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width * MajiangFlameGame.selfWidthRadio,
                MajiangFlameGame.height * MajiangFlameGame.selfHeightRadio),
            paint: fillPaint);

  @override
  Future<void> onLoad() async {}
}
