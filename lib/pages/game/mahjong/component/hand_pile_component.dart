import 'dart:async';

import 'package:colla_chat/pages/game/mahjong/base/format_tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/hand_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_event.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart' as mahjongTile;
import 'package:colla_chat/pages/game/mahjong/base/tile_background_sprite.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/component/tile_component.dart';
import 'package:colla_chat/pages/game/mahjong/component/type_pile_component.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:flame/components.dart';

/// flame引擎渲染的麻将牌
class HandPileComponent extends PositionComponent
    with HasGameRef<MahjongFlameGame> {
  HandPileComponent(this.areaDirection,
      {super.position, super.scale, super.priority, super.size, super.anchor});

  final AreaDirection areaDirection;

  HandPile? get handPile {
    return roomController.getHandPile(areaDirection);
  }

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadHandPile() {
    Vector2 position = Vector2(0, 0);
    TileBackgroundType tileBackgroundType;
    if (areaDirection == AreaDirection.self) {
      tileBackgroundType = TileBackgroundType.handcard;
    } else if (areaDirection == AreaDirection.opponent) {
      tileBackgroundType = TileBackgroundType.opponenthand;
    } else {
      tileBackgroundType = TileBackgroundType.sidehand;
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
            position: Vector2(position.x, position.y - 12));
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
    for (int i = 0; i < handPile!.tiles.length; ++i) {
      mahjongTile.Tile card = handPile!.tiles[i];
      TileComponent cardComponent = TileComponent(
          card, areaDirection, tileBackgroundType,
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

    mahjongTile.Tile? card = handPile?.drawTile;
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

      TileComponent cardComponent = TileComponent(
          card, areaDirection, tileBackgroundType,
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
