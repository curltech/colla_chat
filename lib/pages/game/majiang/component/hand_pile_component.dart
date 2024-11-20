import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/card.dart' as majiangCard;
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/base/format_card.dart';
import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/component/card_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/type_pile_component.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';

/// flame引擎渲染的麻将牌
class HandPileComponent extends PositionComponent
    with HasGameRef<MajiangFlameGame> {
  HandPileComponent(this.areaDirection,
      {super.position, super.scale, super.priority, super.size, super.anchor});

  final AreaDirection areaDirection;

  HandPile? get handPile {
    return roomController.getHandPile(areaDirection);
  }

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadHandPile() {
    double x = 0;
    double y = 0;
    CardBackgroundType cardBackgroundType;
    if (areaDirection == AreaDirection.self) {
      cardBackgroundType = CardBackgroundType.handcard;
    } else if (areaDirection == AreaDirection.opponent) {
      cardBackgroundType = CardBackgroundType.opponenthand;
    } else {
      cardBackgroundType = CardBackgroundType.sidehand;
    }
    for (int i = 0; i < handPile!.touchPiles.length; ++i) {
      TypePile typePile = handPile!.touchPiles[i];
      Vector2 position = Vector2(x, y);
      if (areaDirection == AreaDirection.self) {
        x += 75;
      }
      if (areaDirection == AreaDirection.opponent) {
        x += 37;
      }
      if (areaDirection == AreaDirection.next) {
        y += 28;
      }
      if (areaDirection == AreaDirection.previous) {
        y += 28;
      }
      TypePileComponent typePileComponent =
          TypePileComponent(typePile, areaDirection, position: position);

      add(typePileComponent);
    }
    for (int i = 0; i < handPile!.drawingPiles.length; ++i) {
      TypePile typePile = handPile!.drawingPiles[i];
      Vector2 position = Vector2(x, y);
      if (areaDirection == AreaDirection.self) {
        x += 75;
      }
      if (areaDirection == AreaDirection.opponent) {
        x += 37;
      }
      if (areaDirection == AreaDirection.next) {
        y += 28;
      }
      if (areaDirection == AreaDirection.previous) {
        y += 28;
      }
      TypePileComponent typePileComponent =
          TypePileComponent(typePile, areaDirection, position: position);

      add(typePileComponent);
    }
    for (int i = 0; i < handPile!.cards.length; ++i) {
      majiangCard.Card card = handPile!.cards[i];
      Vector2 position = Vector2(x, y);
      if (areaDirection == AreaDirection.self) {
        x += 75;
      }
      if (areaDirection == AreaDirection.opponent) {
        x += 37;
      }
      if (areaDirection == AreaDirection.next) {
        y += 28;
      }
      if (areaDirection == AreaDirection.previous) {
        y += 28;
      }
      CardComponent cardComponent = CardComponent(
          card, areaDirection, cardBackgroundType,
          position: position);
      add(cardComponent);
    }

    majiangCard.Card? card = handPile?.takeCard;
    if (card != null) {
      if (areaDirection == AreaDirection.self) {
        x += 20;
      }
      if (areaDirection == AreaDirection.opponent) {
        x += 15;
      }
      if (areaDirection == AreaDirection.next) {
        y += 10;
      }
      if (areaDirection == AreaDirection.previous) {
        y += 10;
      }

      Vector2 position = Vector2(x, y);
      CardComponent cardComponent = CardComponent(
          card, areaDirection, cardBackgroundType,
          position: position);
      add(cardComponent);
    }
  }

  @override
  FutureOr<void> onLoad() {
    loadHandPile();

    return super.onLoad();
  }
}
