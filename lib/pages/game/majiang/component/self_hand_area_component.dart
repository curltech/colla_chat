import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 自己手牌区域
class SelfHandAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.teal
    ..style = PaintingStyle.fill;

  SelfHandAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(
                    MajiangFlameGame.width * MajiangFlameGame.selfWidthRadio),
                MajiangFlameGame.y(MajiangFlameGame.height *
                    (1 - MajiangFlameGame.selfHeightRadio))),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width * MajiangFlameGame.selfHandWidthRadio,
                MajiangFlameGame.height * MajiangFlameGame.selfHeightRadio),
            paint: fillPaint);

  @override
  Future<void> onLoad() async {}
}
