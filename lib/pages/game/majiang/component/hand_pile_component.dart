import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/card.dart' as majiangCard;
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/base/format_card.dart';
import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/component/card_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/type_pile_component.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// flame引擎渲染的麻将牌
class HandPileComponent extends PositionComponent
    with TapCallbacks, HasGameRef<MajiangFlameGame> {
  HandPileComponent(this.handPile, this.direction,
      {super.position, super.scale, super.priority, super.size, super.anchor});

  final HandPile handPile;

  /// 0:自己，1:下家，2:对家，3:上家
  final int direction;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadHandPile() {
    double x = 0;
    double y = 0;
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
      Vector2 position = Vector2(x, y);
      if (direction == 0) {
        x += 75;
      }
      if (direction == 2) {
        x += 37;
      }
      if (direction == 1) {
        y += 28;
      }
      if (direction == 3) {
        y += 28;
      }
      TypePileComponent typePileComponent =
          TypePileComponent(typePile, direction, position: position);

      add(typePileComponent);
    }
    for (int i = 0; i < handPile.drawingPiles.length; ++i) {
      TypePile typePile = handPile.touchPiles[i];
      Vector2 position = Vector2(x, y);
      if (direction == 0) {
        x += 75;
      }
      if (direction == 2) {
        x += 37;
      }
      if (direction == 1) {
        y += 28;
      }
      if (direction == 3) {
        y += 28;
      }
      TypePileComponent typePileComponent =
          TypePileComponent(typePile, direction, position: position);

      add(typePileComponent);
    }
    for (int i = 0; i < handPile.cards.length; ++i) {
      majiangCard.Card card = handPile.cards[i];
      Vector2 position = Vector2(x, y);
      if (direction == 0) {
        x += 75;
      }
      if (direction == 2) {
        x += 37;
      }
      if (direction == 1) {
        y += 28;
      }
      if (direction == 3) {
        y += 28;
      }
      CardComponent cardComponent = CardComponent(
          card, direction, cardBackgroundType,
          position: position);
      add(cardComponent);
    }

    majiangCard.Card? card = handPile.takeCard;
    if (card != null) {
      if (direction == 0) {
        x += 20;
      }
      if (direction == 2) {
        x += 15;
      }
      if (direction == 1) {
        y += 10;
      }
      if (direction == 3) {
        y += 10;
      }

      Vector2 position = Vector2(x, y);
      CardComponent cardComponent = CardComponent(
          card, direction, cardBackgroundType,
          position: position);
      add(cardComponent);
    }
  }

  @override
  FutureOr<void> onLoad() {
    loadHandPile();

    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    /// 点击自家的牌表示打牌
    if (direction == 0) {}
  }
}
