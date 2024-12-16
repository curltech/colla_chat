import 'dart:async';

import 'package:colla_chat/pages/game/mahjong/base/tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile_background_sprite.dart';
import 'package:colla_chat/pages/game/mahjong/base/format_tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/component/tile_component.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:universal_html/html.dart';

/// flame引擎渲染的麻将牌
class TypePileComponent extends PositionComponent
    with TapCallbacks, HasGameRef<MahjongFlameGame> {
  TypePileComponent(this.typePile, this.areaDirection, {super.position});

  final TypePile typePile;

  final AreaDirection areaDirection;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadTypePile() {
    TileBackgroundType cardBackgroundType;
    if (areaDirection == AreaDirection.self) {
      cardBackgroundType = TileBackgroundType.touchcard;
    } else if (areaDirection == AreaDirection.opponent) {
      cardBackgroundType = TileBackgroundType.touchcard;
    } else {
      cardBackgroundType = TileBackgroundType.sidecard;
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
    for (int i = 0; i < typePile.tiles.length; ++i) {
      Tile card = typePile.tiles[i];
      TileComponent cardComponent = TileComponent(
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
