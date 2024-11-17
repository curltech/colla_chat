import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 自己河牌区域
class SelfWasteAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.pinkAccent
    ..style = PaintingStyle.fill;

  SelfWasteAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(MajiangFlameGame.width *
                    (MajiangFlameGame.previousWidthRadio +
                        MajiangFlameGame.previousHandWidthRadio +
                        MajiangFlameGame.previousWasteWidthRadio)),
                MajiangFlameGame.y(MajiangFlameGame.height *
                    (1 -
                        MajiangFlameGame.selfHeightRadio -
                        MajiangFlameGame.selfWasteHeightRadio))),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width * MajiangFlameGame.selfWasteWidthRadio,
                MajiangFlameGame.height *
                    MajiangFlameGame.selfWasteHeightRadio),
            paint: fillPaint);

  @override
  Future<void> onLoad() async {}
}