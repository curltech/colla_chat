import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/waste_pile.dart';
import 'package:colla_chat/pages/game/majiang/component/card_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// flame引擎渲染的麻将牌
class WastePileComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameRef<MajiangFlameGame> {
  WastePileComponent(this.areaDirection, {super.position, super.scale});

  final AreaDirection areaDirection;

  WastePile? get wastePile {
    return roomController.getWastePile(areaDirection);
  }

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadWastePile() {
    CardBackgroundType cardBackgroundType;
    if (areaDirection == AreaDirection.self) {
      cardBackgroundType = CardBackgroundType.touchcard;
    } else if (areaDirection == AreaDirection.opponent) {
      cardBackgroundType = CardBackgroundType.touchcard;
    } else {
      cardBackgroundType = CardBackgroundType.sidecard;
    }
    for (int i = 0; i < wastePile!.cards.length; ++i) {
      Card card = wastePile!.cards[i];
      Vector2? position;
      if (areaDirection == AreaDirection.self) {
        position = Vector2(i * 80, 0);
      }
      if (areaDirection == AreaDirection.opponent) {
        position = Vector2(i * 70, 0);
      }
      if (areaDirection == AreaDirection.next) {
        position = Vector2(0, i * 70);
      }
      if (areaDirection == AreaDirection.previous) {
        position = Vector2(0, i * 70);
      }
      CardComponent cardComponent = CardComponent(
          card, areaDirection, cardBackgroundType,
          position: position!);
      add(cardComponent);
    }
  }

  @override
  FutureOr<void> onLoad() {
    loadWastePile();

    return super.onLoad();
  }
}
