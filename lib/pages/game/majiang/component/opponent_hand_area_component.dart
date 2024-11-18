import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/component/hand_pile_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 对家的手牌区域
class OpponentHandAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.blueGrey
    ..style = PaintingStyle.fill;

  HandPile? handPile;
  HandPileComponent? handPileComponent;

  OpponentHandAreaComponent()
      : super(
            position: Vector2(
                MajiangFlameGame.x(MajiangFlameGame.width *
                    MajiangFlameGame.opponentWidthRadio),
                MajiangFlameGame.y(0)),
            anchor: Anchor.topLeft,
            size: Vector2(
                MajiangFlameGame.width *
                    MajiangFlameGame.opponentHandWidthRadio,
                MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio),
            paint: fillPaint);

  loadHandPile() {
    if (handPileComponent != null) {
      remove(handPileComponent!);
    }
    if (handPile != null) {
      handPileComponent = HandPileComponent(handPile!, 2);
      add(handPileComponent!);
    }
  }

  @override
  Future<void> onLoad() async {}
}
