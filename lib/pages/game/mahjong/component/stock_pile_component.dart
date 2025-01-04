import 'dart:async';

import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/base/stock_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart' as mahjongTile;
import 'package:colla_chat/pages/game/mahjong/base/tile_background_sprite.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/component/tile_component.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// 摸牌的麻将牌
class StockPileComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameRef<MahjongFlameGame> {
  StockPileComponent({super.scale}) {
    position = Vector2(5, 20);
  }

  StockPile? get stockPile {
    return roomController.room.value?.currentRound?.stockPile;
  }

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadStockPile() {
    StockPile? stockPile = this.stockPile;
    if (stockPile == null) {
      return;
    }
    Round? round = roomController.currentRound;
    if (round == null) {
      return;
    }
    int length = 26;
    int barCount = round.barCount;
    if (barCount.isOdd) {
      length = 25;
    }
    TileBackgroundType tileBackgroundType = TileBackgroundType.opponentbar;

    int priority = 12;
    List<mahjongTile.Tile> tiles;
    if (stockPile.tiles.length > length) {
      tiles = stockPile.tiles.sublist(stockPile.tiles.length - length);
    } else {
      tiles = [...stockPile.tiles];
    }
    length = length - 6;
    double initX;
    if (length.isOdd) {
      initX = roomController.width * MahjongFlameGame.stockWidthRadio -
          (length + 1) / 2 * 35;
    } else {
      initX = roomController.width * MahjongFlameGame.stockWidthRadio -
          (length / 2) * 35;
    }
    double x = initX;
    double y = 0;
    List<mahjongTile.Tile> upCards = [];
    List<mahjongTile.Tile> downCards = [];
    mahjongTile.Tile? lastCard;
    if (barCount.isOdd && tiles.isNotEmpty) {
      lastCard = tiles.removeLast();
    }
    if (tiles.length.isOdd && tiles.isNotEmpty) {
      mahjongTile.Tile firstCard = tiles.removeAt(0);
      downCards.add(firstCard);
    }
    for (int i = 0; i < tiles.length; ++i) {
      if (i.isOdd) {
        downCards.add(tiles[i]);
      } else {
        upCards.add(tiles[i]);
      }
    }
    if (lastCard != null) {
      downCards.add(lastCard);
    }
    for (int i = 0; i < downCards.length; ++i) {
      mahjongTile.Tile tile = downCards[i];
      Vector2 position = Vector2(x, y);
      x += 35;
      TileComponent tileComponent = TileComponent(
          tile, AreaDirection.self, tileBackgroundType,
          position: position, priority: priority);
      add(tileComponent);
    }
    x = initX;
    y = 0;
    if (downCards.length == upCards.length + 2) {
      x += 35;
    }
    if (downCards.length == upCards.length + 1 && !barCount.isOdd) {
      x += 35;
    }
    for (int i = 0; i < upCards.length; ++i) {
      mahjongTile.Tile tile = upCards[i];
      y = -10;
      Vector2 position = Vector2(x, y);
      x += 35;
      TileComponent tileComponent = TileComponent(
          tile, AreaDirection.self, tileBackgroundType,
          position: position, priority: priority);
      add(tileComponent);
    }
  }

  @override
  FutureOr<void> onLoad() {
    loadStockPile();

    return super.onLoad();
  }
}
