import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/base/format_card.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/component/card_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:universal_html/html.dart';

/// flame引擎渲染的麻将牌
class TypePileComponent extends PositionComponent
    with TapCallbacks, HasGameRef<MajiangFlameGame> {
  TypePileComponent(this.typePile, this.areaDirection, {super.position});

  final TypePile typePile;

  final AreaDirection areaDirection;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadTypePile() {
    CardBackgroundType cardBackgroundType;
    if (areaDirection == AreaDirection.self) {
      cardBackgroundType = CardBackgroundType.touchcard;
    } else if (areaDirection == AreaDirection.opponent) {
      cardBackgroundType = CardBackgroundType.touchcard;
    } else {
      cardBackgroundType = CardBackgroundType.sidecard;
    }
    Vector2 position = Vector2(0, 0);
    if (areaDirection == AreaDirection.self) {
      position.x = position.x + 10;
      width = position.x;
    }
    if (areaDirection == AreaDirection.opponent) {
      position.x = position.x + 10;
      width = position.x;
    }
    if (areaDirection == AreaDirection.next) {
      position.y = position.y + 10;
      height = position.y;
    }
    if (areaDirection == AreaDirection.previous) {
      position.y = position.y + 10;
      height = position.y;
    }
    for (int i = 0; i < typePile.cards.length; ++i) {
      Card card = typePile.cards[i];
      CardComponent cardComponent = CardComponent(
          card, areaDirection, cardBackgroundType,
          position: position);
      add(cardComponent);
      if (areaDirection == AreaDirection.self) {
        position.x = position.x + 43;
        width = position.x;
      }
      if (areaDirection == AreaDirection.opponent) {
        position.x = position.x + 43;
        width = position.x;
      }
      if (areaDirection == AreaDirection.next) {
        position.y = position.y + 32;
        height = position.y;
      }
      if (areaDirection == AreaDirection.previous) {
        position.y = position.y + 32;
        height = position.y;
      }
    }
  }

  @override
  FutureOr<void> onLoad() {
    loadTypePile();

    return super.onLoad();
  }
}
