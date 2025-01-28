import 'package:colla_chat/pages/game/mahjong/base/pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';

/// 牌形牌
class TypePile extends Pile {
  late TileType tileType;
  int? source;

  TypePile({super.tiles}) {
    tileType = _initTileType();
  }

  /// 多张牌组成的牌形
  TileType _initTileType() {
    sort();
    if (tiles.length == 2 && tiles[0] == tiles[1]) {
      return TileType.pair;
    } else if (tiles.length == 4 &&
        tiles[0] == tiles[1] &&
        tiles[0] == tiles[2] &&
        tiles[0] == tiles[3]) {
      return TileType.bar;
    } else if (tiles.length == 3 &&
        tiles[0] == tiles[1] &&
        tiles[0] == tiles[2]) {
      return TileType.touch;
    } else if (tiles.length == 3 &&
        tiles[0].next(tiles[1]) &&
        tiles[1].next(tiles[2])) {
      return TileType.straight;
    }

    return TileType.single;
  }

  TypePile.fromJson(Map json) {
    List? tiles = json['tiles'];
    if (tiles != null) {
      this.tiles = [];
      for (var tile in tiles) {
        this.tiles.add(Tile.fromJson(tile));
      }
    }
    if (json['tileType'] != null) {
      tileType = StringUtil.enumFromString(TileType.values, json['tileType'])!;
    }
    source = json['source'];
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'tiles': JsonUtil.toJson(tiles),
      'tileType': tileType.name,
      'source': source
    };
  }
}

/// 经过格式化处理的手牌，被按照花色，牌形进行拆分，用于判断是否胡牌
class FormatPile extends Pile {
  final List<TypePile> typePiles = [];

  FormatPile({super.tiles}) {
    sort();
  }

  /// 是否13幺
  bool check13_1() {
    typePiles.clear();
    int length = tiles.length;
    if (length != 14) {
      return false;
    }
    for (Tile tile in tiles) {
      if (!tile.is19()) {
        return false;
      }
    }
    int count = countPair();
    if (count != 1) {
      return false;
    }

    return true;
  }

  /// 是否幺9对对胡
  bool check1_9(List<String> tiles) {
    for (TypePile typePile in typePiles) {
      if (!typePile.tiles[0].is19()) {
        return false;
      }
    }
    return true;
  }

  /// 计算19牌的数量
  int count19() {
    int count = 0;
    for (int i = 0; i < tiles.length - 1; i++) {
      Tile tile = tiles[i];
      if (tile.is19()) {
        count++;
      }
    }

    return count;
  }

  /// 计算花色的数量
  Map<Suit, int> countSuit() {
    Map<Suit, int> counts = {};
    for (int i = 0; i < tiles.length - 1; i++) {
      Tile tile = tiles[i];
      if (tile.suit != Suit.none) {
        int? count = counts[tile.suit];
        count = count ?? 0;
        counts[tile.suit] = count + 1;
      }
    }

    return counts;
  }

  /// 分拆成对子，返回对子的个数
  int countPair() {
    int count = 0;
    typePiles.clear();
    for (int i = 0; i < tiles.length - 1; i++) {
      Tile tile = tiles[i];
      Tile next = tiles[i + 1];

      /// 成对，去掉对子将牌
      if (tile == next) {
        TypePile pairPile = TypePile(tiles: [tile, next]);
        typePiles.add(pairPile);
        count++;
        i++;
      }
    }

    return count;
  }

  /// 相同两对的数目
  /// -1，表示不是7对
  /// 0，是7对
  /// 其他，相同两对的数目
  int countLux7Pair() {
    int count = countPair();
    if (count == 7) {
      count = 0;
      for (int i = 0; i < typePiles.length - 1; ++i) {
        TypePile pairPile = typePiles[i];
        TypePile next = typePiles[i + 1];
        if (pairPile.tiles[0] == next.tiles[0]) {
          count++;
        }
      }
    } else {
      count = -1;
    }

    return count;
  }

  WinType? check() {
    bool wind = false; //是否有风牌
    bool oneNine = true; //是否有都是19牌
    bool touch = true; //是否有都是碰或者杠
    bool pure = true; //是否有两种以上的花色
    Suit? previousSuit;
    for (int i = 0; i < typePiles.length; ++i) {
      TypePile typePile = typePiles[i];
      Tile tile = typePile.tiles[0];
      if (!tile.is19()) {
        oneNine = false;
      }
      if (typePile.tileType == TileType.straight) {
        touch = false;
      }

      if (tile.suit == Suit.wind) {
        wind = true;
      } else if (previousSuit != null) {
        if (previousSuit != tile.suit && previousSuit != Suit.wind) {
          pure = false;
        }
      }
      previousSuit = tile.suit;
    }
    if (touch) {
      if (oneNine) {
        return WinType.oneNine;
      }
      if (pure) {
        if (wind) {
          return WinType.mixTouch;
        } else {
          return WinType.pureTouch;
        }
      } else {
        return WinType.touch;
      }
    } else {
      if (pure) {
        if (wind) {
          return WinType.mixOneType;
        } else {
          return WinType.pureOneType;
        }
      } else {
        return WinType.small;
      }
    }
  }

  bool split() {
    typePiles.clear();
    int length = tiles.length;
    if (length == 2 ||
        length == 5 ||
        length == 8 ||
        length == 11 ||
        length == 14) {
      for (int i = 1; i < length; ++i) {
        Tile tile = tiles[i];
        Tile previous = tiles[i - 1];

        /// 成对，去掉对子将牌
        if (tile == previous) {
          List<Tile> subCards = tiles.sublist(0, i - 1);
          List<Tile> cs = tiles.sublist(i + 1);
          subCards.addAll(cs);

          /// 对无将牌的牌分类，遍历每种花色
          Map<Suit, List<Tile>> suitCardMap = suit(subCards);
          bool success = true;
          typePiles.clear();
          for (var suitEntry in suitCardMap.entries) {
            List<Tile> suitCards = suitEntry.value;
            Map<TileType, List<TypePile>>? typePileMap =
                splitTypePile(suitCards);
            // 这种花色没有合适的胡牌组合，说明将牌提取错误
            if (typePileMap == null) {
              success = false;
              typePiles.clear();
              break;
            } else {
              // 找到这种花色胡牌的组合
              for (var entry in typePileMap.entries) {
                List<TypePile> scs = entry.value;
                typePiles.addAll(scs);
              }
            }
          }
          // 找到所有花色胡牌的组合，说明将牌提取正确
          if (success) {
            TypePile typePile = TypePile(tiles: [previous, tile]);
            typePiles.add(typePile);

            return true;
          }
        }
      }
    }

    return false;
  }

  /// 按照花色牌分类
  Map<Suit, List<Tile>> suit(List<Tile> tiles) {
    Map<Suit, List<Tile>> tileMap = {};
    for (int i = 0; i < tiles.length; ++i) {
      Tile tile = tiles[i];
      Suit suit = tile.suit;
      if (!tileMap.containsKey(suit)) {
        tileMap[suit] = [];
      }
      List<Tile> suitTiles = tileMap[suit]!;
      suitTiles.add(tile);
    }

    return tileMap;
  }

  /// 同花色牌形的拆分，其中的一对将牌已经抽出，所以张数只能是3，6，9，12
  Map<TileType, List<TypePile>>? splitTypePile(List<Tile> tiles) {
    int length = tiles.length;
    if (length != 3 && length != 6 && length != 9 && length != 12) {
      return null;
    }
    Map<TileType, List<TypePile>> tileMap = {};
    int mod = length ~/ 3;
    for (int i = 0; i < mod; ++i) {
      int start = i * 3;
      List<Tile> subTiles = tiles.sublist(start, start + 3);
      TypePile typePile = TypePile(tiles: subTiles);
      if (typePile.tileType != TileType.touch &&
          typePile.tileType != TileType.straight) {
        if (length > start + 3) {
          Tile tile = tiles[start + 3];
          tiles[start + 3] = tiles[start + 2];
          tiles[start + 2] = tile;
          subTiles = tiles.sublist(start, start + 3);
          typePile = TypePile(tiles: subTiles);
        }
      }
      if (typePile.tileType == TileType.straight ||
          typePile.tileType == TileType.touch) {
        if (!tileMap.containsKey(typePile.tileType)) {
          tileMap[typePile.tileType] = [];
        }
        List<TypePile> cs = tileMap[typePile.tileType]!;
        cs.add(typePile);
      } else {
        return null;
      }
    }

    return tileMap;
  }
}
