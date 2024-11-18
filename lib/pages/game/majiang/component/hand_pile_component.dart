import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/base/format_card.dart';
import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/component/card_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/type_pile_component.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// flame引擎渲染的麻将牌
class HandPileComponent extends RectangleComponent
    with DragCallbacks, TapCallbacks, HasGameRef<MajiangFlameGame> {
  HandPileComponent(this.handPile, this.direction,
      {super.position, super.anchor = Anchor.center});

  final HandPile handPile;

  /// 0:自己，1:下家，2:对家，3:上家
  final int direction;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void _loadHandPile() {
    CardBackgroundType cardBackgroundType;
    if (direction == 0) {
      cardBackgroundType = CardBackgroundType.handcard;
    } else if (direction == 2) {
      cardBackgroundType = CardBackgroundType.opponenthand;
    } else {
      cardBackgroundType = CardBackgroundType.sidehand;
    }
    for (int i = 0; i < handPile.touchPiles.length; ++i) {
      TypePile typePile = handPile.touchPiles[i];
      Vector2? position;
      if (direction == 0) {
        position = Vector2(i * 80, 0);
      }
      if (direction == 2) {
        position = Vector2(i * 70, 0);
      }
      if (direction == 1) {
        position = Vector2(0, i * 70);
      }
      if (direction == 3) {
        position = Vector2(0, i * 70);
      }
      TypePileComponent typePileComponent =
          TypePileComponent(typePile, direction, position: position);

      add(typePileComponent);
    }
    for (int i = 0; i < handPile.drawingPiles.length; ++i) {
      TypePile typePile = handPile.touchPiles[i];
      Vector2? position;
      if (direction == 0) {
        position = Vector2(i * 80, 0);
      }
      if (direction == 2) {
        position = Vector2(i * 70, 0);
      }
      if (direction == 1) {
        position = Vector2(0, i * 70);
      }
      if (direction == 3) {
        position = Vector2(0, i * 70);
      }
      TypePileComponent typePileComponent =
          TypePileComponent(typePile, direction, position: position);

      add(typePileComponent);
    }
    for (int i = 0; i < handPile.cards.length; ++i) {
      Card card = handPile.cards[i];
      Vector2? position;
      if (direction == 0) {
        position = Vector2(i * 60, 0);
      }
      if (direction == 2) {
        position = Vector2(i * 70, 0);
      }
      if (direction == 1) {
        position = Vector2(0, i * 70);
      }
      if (direction == 3) {
        position = Vector2(0, i * 70);
      }
      CardComponent cardComponent = CardComponent(
          card, direction, cardBackgroundType,
          position: position!);
      add(cardComponent);
    }
  }

  @override
  FutureOr<void> onLoad() {
    _loadHandPile();

    return super.onLoad();
  }
}
