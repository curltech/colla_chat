import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
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
        roomController
            .x(roomController.width * (1 - MahjongFlameGame.settingWidthRadio)),
        roomController.y(0));
    size = Vector2(roomController.width * MahjongFlameGame.settingWidthRadio,
        roomController.height * MahjongFlameGame.opponentHeightRadio);
    paint = Paint()
      ..color = Colors.white.withAlpha(0)
      ..style = PaintingStyle.fill;
  }

  @override
  Future<void> onLoad() async {}
}
