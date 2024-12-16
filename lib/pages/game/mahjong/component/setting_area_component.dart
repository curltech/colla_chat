import 'dart:ui';

import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 右上角的设置按钮区域
class SettingAreaComponent extends RectangleComponent
    with HasGameRef<MahjongFlameGame> {
  SettingAreaComponent() {
    _init();
  }

  _init() {
    position = Vector2(
        MahjongFlameGame.x(
            MahjongFlameGame.width * (1 - MahjongFlameGame.settingWidthRadio)),
        MahjongFlameGame.y(0));
    size = Vector2(MahjongFlameGame.width * MahjongFlameGame.settingWidthRadio,
        MahjongFlameGame.height * MahjongFlameGame.opponentHeightRadio);
    paint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.fill;
  }

  @override
  Future<void> onLoad() async {}
}
