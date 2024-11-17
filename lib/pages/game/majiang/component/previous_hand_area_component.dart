import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 上家手牌区域
class PreviousHandAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.purple
    ..style = PaintingStyle.fill;

  PreviousHandAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(MajiangFlameGame.width *
                    MajiangFlameGame.previousWidthRadio),
                MajiangFlameGame.y(MajiangFlameGame.height *
                    MajiangFlameGame.opponentHeightRadio)),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width *
                    MajiangFlameGame.previousHandWidthRadio,
                MajiangFlameGame.height * MajiangFlameGame.previousHeightRadio),
            paint: fillPaint);

  @override
  Future<void> onLoad() async {}
}
