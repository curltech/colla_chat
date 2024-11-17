import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 下家的手牌区域
class NextHandAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.fill;

  NextHandAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(MajiangFlameGame.width *
                    (1 -
                        MajiangFlameGame.nextWidthRadio -
                        MajiangFlameGame.nextHandWidthRadio)),
                MajiangFlameGame.y(MajiangFlameGame.height *
                    MajiangFlameGame.opponentHeightRadio)),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width * MajiangFlameGame.nextHandWidthRadio,
                MajiangFlameGame.height * MajiangFlameGame.nextHeightRadio),
            paint: fillPaint);

  @override
  Future<void> onLoad() async {}

// @override
// void render(Canvas canvas) {}
}
