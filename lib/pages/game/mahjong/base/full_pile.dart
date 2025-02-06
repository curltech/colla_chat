import 'package:colla_chat/pages/game/mahjong/base/pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart';

/// 完整的一副麻将
class FullPile extends Pile {
  FullPile() : super() {
    init();
  }

  init() async {
    for (var windSuit in WindSuit.values) {
      for (int i = 0; i < 4; ++i) {
        Tile tile = Tile(i, Suit.wind, windSuit: windSuit);
        tiles.add(tile);
      }
    }
    for (int i = 1; i < 10; ++i) {
      for (int j = 0; j < 4; ++j) {
        Tile tile = Tile(j, Suit.suo, rank: i);
        tiles.add(tile);
      }
    }
    for (int i = 1; i < 10; ++i) {
      for (int j = 0; j < 4; ++j) {
        Tile tile = Tile(j, Suit.tong, rank: i);
        tiles.add(tile);
      }
    }
    for (int i = 1; i < 10; ++i) {
      for (int j = 0; j < 4; ++j) {
        Tile tile = Tile(j, Suit.wan, rank: i);
        tiles.add(tile);
      }
    }
  }
}

/// 原始的麻将牌
final FullPile fullPile = FullPile();
