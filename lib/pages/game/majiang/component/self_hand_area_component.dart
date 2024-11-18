import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/component/hand_pile_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// 自己手牌区域
class SelfHandAreaComponent extends RectangleComponent
    with TapCallbacks, HasGameRef<MajiangFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.teal
    ..style = PaintingStyle.fill;

  HandPileComponent? handPileComponent;

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

  loadHandPile() {
    if (handPileComponent != null) {
      remove(handPileComponent!);
    }
    Room? room = roomController.room.value;
    if (room != null) {
      HandPile? handPile = room.currentRound?.roundParticipants[0].handPile;
      if (handPile != null) {
        handPileComponent = HandPileComponent(handPile, 0);
        add(handPileComponent!);
      }
    }
  }

  @override
  void onTapDown(_) {
    loadHandPile();
  }

  @override
  Future<void> onLoad() async {}
}
