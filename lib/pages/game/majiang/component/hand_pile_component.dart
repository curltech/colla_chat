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
    Vector2 position = Vector2(0, 0);
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
      TypePileComponent? typePileComponent;
      if (areaDirection == AreaDirection.self) {
        typePileComponent = TypePileComponent(typePile, areaDirection,
            position: Vector2(position.x, position.y));
      }
      if (areaDirection == AreaDirection.opponent) {
        typePileComponent = TypePileComponent(typePile, areaDirection,
            position: Vector2(position.x, position.y-12));
      }
      if (areaDirection == AreaDirection.next) {
        typePileComponent = TypePileComponent(typePile, areaDirection,
            position: Vector2(position.x, position.y));
      }
      if (areaDirection == AreaDirection.previous) {
        typePileComponent = TypePileComponent(typePile, areaDirection,
            position: Vector2(position.x - 25, position.y));
      }
      add(typePileComponent!);
      if (areaDirection == AreaDirection.self) {
        position.x += typePileComponent.width;
      }
      if (areaDirection == AreaDirection.opponent) {
        position.x += typePileComponent.width;
      }
      if (areaDirection == AreaDirection.next) {
        position.y += typePileComponent.height;
      }
      if (areaDirection == AreaDirection.previous) {
        position.y += typePileComponent.height;
      }
    }
    for (int i = 0; i < handPile!.drawingPiles.length; ++i) {
      TypePile typePile = handPile!.drawingPiles[i];
      TypePileComponent typePileComponent =
          TypePileComponent(typePile, areaDirection, position: position);
      add(typePileComponent);
      if (areaDirection == AreaDirection.self) {
        position.x += typePileComponent.width;
      }
      if (areaDirection == AreaDirection.opponent) {
        position.x += typePileComponent.width;
      }
      if (areaDirection == AreaDirection.next) {
        position.y += typePileComponent.height;
      }
      if (areaDirection == AreaDirection.previous) {
        position.y += typePileComponent.height;
      }
    }
    if (areaDirection == AreaDirection.self) {
      position.x += 10;
    }
    if (areaDirection == AreaDirection.opponent) {
      position.x += 10;
    }
    if (areaDirection == AreaDirection.next) {
      position.y += 10;
    }
    if (areaDirection == AreaDirection.previous) {
      position.y += 10;
    }
    for (int i = 0; i < handPile!.cards.length; ++i) {
      majiangCard.Card card = handPile!.cards[i];
      CardComponent cardComponent = CardComponent(
          card, areaDirection, cardBackgroundType,
          position: position);
      add(cardComponent);
      if (areaDirection == AreaDirection.self) {
        position.x += 75;
      }
      if (areaDirection == AreaDirection.opponent) {
        position.x += 37;
      }
      if (areaDirection == AreaDirection.next) {
        position.y += 28;
      }
      if (areaDirection == AreaDirection.previous) {
        position.y += 28;
      }
    }

    majiangCard.Card? card = handPile?.takeCard;
    if (card != null) {
      if (areaDirection == AreaDirection.self) {
        position.x += 20;
      }
      if (areaDirection == AreaDirection.opponent) {
        position.x += 15;
      }
      if (areaDirection == AreaDirection.next) {
        position.y += 10;
      }
      if (areaDirection == AreaDirection.previous) {
        position.y += 10;
      }

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
