import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/base/format_card.dart';
import 'package:colla_chat/pages/game/majiang/component/card_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// flame引擎渲染的麻将牌
class TypePileComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameRef<MajiangFlameGame> {
  TypePileComponent(this.typePile, this.direction, {super.position});

  final TypePile typePile;

  /// 0:自己，1:下家，2:对家，3:上家
  final int direction;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadTypePile() {
    CardBackgroundType cardBackgroundType;
    if (direction == 0) {
      cardBackgroundType = CardBackgroundType.touchcard;
    } else if (direction == 2) {
      cardBackgroundType = CardBackgroundType.touchcard;
    } else {
      cardBackgroundType = CardBackgroundType.sidecard;
    }
    double x = 0;
    double y = 0;
    for (int i = 0; i < typePile.cards.length; ++i) {
      Card card = typePile.cards[i];
      if (direction == 0) {
        x += i * 75;
      }
      if (direction == 2) {
        x += i * 37;
      }
      if (direction == 1) {
        y += i * 28;
      }
      if (direction == 3) {
        y += i * 28;
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
    loadTypePile();

    return super.onLoad();
  }
}
