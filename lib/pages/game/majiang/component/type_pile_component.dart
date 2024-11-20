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
    with DragCallbacks, TapCallbacks, HasGameRef<MajiangFlameGame> {
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
    double x = 0;
    double y = 0;
    for (int i = 0; i < typePile.cards.length; ++i) {
      Card card = typePile.cards[i];
      if (areaDirection == AreaDirection.self) {
        x += i * 75;
      }
      if (areaDirection == AreaDirection.opponent) {
        x += i * 37;
      }
      if (areaDirection == AreaDirection.next) {
        y += i * 28;
      }
      if (areaDirection == AreaDirection.previous) {
        y += i * 28;
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
    loadTypePile();

    return super.onLoad();
  }
}
