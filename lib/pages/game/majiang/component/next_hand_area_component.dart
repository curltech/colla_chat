import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/component/hand_pile_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 下家的手牌区域
class NextHandAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.fill;

  HandPile? handPile;

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

  void _loadHandPile() {
    HandPileComponent handPileComponent = HandPileComponent(handPile!, 1);
    add(handPileComponent);
  }

  @override
  Future<void> onLoad() async {
    _loadHandPile();
    return super.onLoad();
  }
}
