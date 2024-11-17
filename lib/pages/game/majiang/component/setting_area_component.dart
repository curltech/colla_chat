import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 右上角的设置按钮区域
class SettingAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.lightBlueAccent
    ..style = PaintingStyle.fill;

  SettingAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(MajiangFlameGame.width *
                    (1 - MajiangFlameGame.settingWidthRadio)),
                MajiangFlameGame.y(0)),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width * MajiangFlameGame.settingWidthRadio,
                MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio),
            paint: fillPaint);

  @override
  Future<void> onLoad() async {}
}
