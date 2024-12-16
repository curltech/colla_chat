import 'dart:math';

import 'package:colla_chat/pages/game/mahjong/base/tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/tool/json_util.dart';

/// 一摞麻将牌，可以认为是一个序列的牌
/// 比如每家的手牌和打出的河牌，未发的牌
/// 以及杠牌，碰牌，吃牌
class Pile {
  late List<Tile> tiles;

  Pile({List<Tile>? tiles}) {
    if (tiles == null) {
      this.tiles = [];
    } else {
      this.tiles = [...tiles];
    }
  }

  Pile.fromJson(Map json) {
    List? tiles = json['tiles'];
    if (tiles != null) {
      this.tiles = [];
      for (var tile in tiles) {
        this.tiles.add(Tile.fromJson(tile));
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tiles': JsonUtil.toJson(tiles),
    };
  }

  static sortTile(List<Tile> tiles) {
    tiles.sort((Tile a, Tile b) {
      if (a.suit != Suit.wind && b.suit != Suit.wind) {
        return a.toString().compareTo(b.toString());
      } else if (a.suit == Suit.wind && b.suit != Suit.wind) {
        return -1;
      } else if (a.suit != Suit.wind && b.suit == Suit.wind) {
        return 1;
      } else {
        return a.windSuit!.index.compareTo(b.windSuit!.index);
      }
    });
  }

  /// 排序
  sort() {
    sortTile(tiles);
  }

  /// 洗牌
  shuffle([Random? random]) {
    tiles.shuffle(random);
  }
}
