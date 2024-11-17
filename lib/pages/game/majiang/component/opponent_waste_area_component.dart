import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 对家河牌区域
class OpponentWasteAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.green
    ..style = PaintingStyle.fill;

  OpponentWasteAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(MajiangFlameGame.width *
                    (MajiangFlameGame.previousWidthRadio +
                        MajiangFlameGame.previousHandWidthRadio +
                        MajiangFlameGame.previousWasteWidthRadio)),
                MajiangFlameGame.y(MajiangFlameGame.height *
                    MajiangFlameGame.opponentHeightRadio)),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width *
                    MajiangFlameGame.opponentWasteWidthRadio,
                MajiangFlameGame.height *
                    MajiangFlameGame.opponentWasteHeightRadio),
            paint: fillPaint);

  @override
  Future<void> onLoad() async {}
}
