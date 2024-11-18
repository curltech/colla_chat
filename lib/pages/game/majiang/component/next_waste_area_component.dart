import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/waste_pile.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/waste_pile_component.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 下家的河牌区域
class NextWasteAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.fill;

  WastePile? wastePile;
  WastePileComponent? wastePileComponent;

  NextWasteAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(MajiangFlameGame.width *
                    (1 -
                        MajiangFlameGame.nextWidthRadio -
                        MajiangFlameGame.nextHandWidthRadio -
                        MajiangFlameGame.nextWasteWidthRadio)),
                MajiangFlameGame.y(MajiangFlameGame.height *
                    MajiangFlameGame.opponentHeightRadio)),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width * MajiangFlameGame.nextWasteWidthRadio,
                MajiangFlameGame.height * MajiangFlameGame.nextHeightRadio),
            paint: fillPaint);

  loadWastePile() {
    if (wastePileComponent != null) {
      remove(wastePileComponent!);
    }
    if (wastePile != null) {
      wastePileComponent = WastePileComponent(wastePile!, 1);
      add(wastePileComponent!);
    }
  }

  @override
  Future<void> onLoad() async {}
}
