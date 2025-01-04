import 'package:colla_chat/pages/game/mahjong/base/pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart';

/// 完整的一副麻将
class FullPile extends Pile {
  final Map<String, Tile> _tileMap = {};

  FullPile() : super() {
    init();
  }

  init() async {
    for (var windSuit in WindSuit.values) {
      Tile tile = Tile(Suit.wind, windSuit: windSuit);
      tiles.add(tile);
      _tileMap[tile.toString()] = tile;
    }
    for (int i = 1; i < 10; ++i) {
      Tile tile = Tile(Suit.suo, rank: i);
      tiles.add(tile);
      _tileMap[tile.toString()] = tile;
    }
    for (int i = 1; i < 10; ++i) {
      Tile tile = Tile(Suit.tong, rank: i);
      tiles.add(tile);
      _tileMap[tile.toString()] = tile;
    }
    for (int i = 1; i < 10; ++i) {
      Tile tile = Tile(Suit.wan, rank: i);
      tiles.add(tile);
      _tileMap[tile.toString()] = tile;
    }
    _tileMap[unknownTile.toString()] = unknownTile;
  }

  Tile? operator [](String key) {
    return _tileMap[key];
  }
}

/// 原始的麻将牌
final FullPile fullPile = FullPile();
