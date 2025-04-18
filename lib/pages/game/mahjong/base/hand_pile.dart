import 'package:colla_chat/pages/game/mahjong/base/format_tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_event.dart';
import 'package:colla_chat/pages/game/mahjong/base/pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';

/// 正在使用的牌，手牌
class HandPile extends Pile {
  //碰，杠牌
  final List<TypePile> touchPiles = [];

  //吃牌
  final List<TypePile> drawingPiles = [];

  /// 刚摸进的牌
  Tile? drawTile;

  DealTileType? drawTileType;

  HandPile({super.tiles});

  HandPile.fromJson(Map json) {
    List? tiles = json['tiles'];
    if (tiles != null) {
      this.tiles = [];
      for (var tile in tiles) {
        this.tiles.add(Tile.fromJson(tile));
      }
    }
    List? touchPiles = json['touchPiles'];
    if (touchPiles != null) {
      for (var touchPile in touchPiles) {
        this.touchPiles.add(TypePile.fromJson(touchPile));
      }
    }
    List? drawingPiles = json['drawingPiles'];
    if (drawingPiles != null) {
      for (var drawingPile in drawingPiles) {
        this.drawingPiles.add(TypePile.fromJson(drawingPile));
      }
    }
    drawTile =
        json['drawTile'] != null ? Tile.fromJson(json['drawTile']) : null;
    drawTileType = json['drawTileType'] != null
        ? StringUtil.enumFromString(DealTileType.values, json['drawTile'])
        : null;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'tiles': JsonUtil.toJson(tiles),
      'drawTile': JsonUtil.toJson(drawTile),
      'drawTileType': drawTileType?.name
    };
  }

  int get total {
    int total = 0;
    for (TypePile touchPile in touchPiles) {
      total += touchPile.tiles.length;
    }
    for (TypePile drawingPile in drawingPiles) {
      total += drawingPile.tiles.length;
    }
    return total + tiles.length + (drawTile == null ? 0 : 1);
  }

  int get count {
    int total = 0;
    total += touchPiles.length * 3;
    total += drawingPiles.length * 3;
    return total + tiles.length + (drawTile == null ? 0 : 1);
  }

  /// 检查碰牌
  int? checkTouch(Tile tile) {
    int length = tiles.length;
    if (length < 2) {
      return null;
    }
    for (int i = 1; i < tiles.length; ++i) {
      if (tile == tiles[i] && tile == tiles[i - 1]) {
        return i - 1;
      }
    }

    return null;
  }

  /// 手牌中是否存在
  @override
  bool exist(Tile tile) {
    if (drawTile == null) {
      return super.exist(tile);
    }
    return super.exist(tile) || drawTile!.same(tile);
  }

  Tile? remove(Tile tile) {
    if (drawTile != null) {
      if (drawTile!.same(tile)) {
        drawTile = null;
        drawTileType = null;

        return tile;
      }
    }
    int? pos;
    for (int i = 0; i < tiles.length; ++i) {
      if (tiles[i].same(tile)) {
        pos = i;
        break;
      }
    }
    if (pos != null) {
      return tiles.removeAt(pos);
    }
    return null;
  }

  TypePile? touch(int pos, Tile tile) {
    if (pos < 0 || pos >= tiles.length - 1) {
      return null;
    }
    if (tiles[pos] != tile) {
      return null;
    }
    if (tiles[pos + 1] != tile) {
      return null;
    }
    Tile? t1 = tiles.removeAt(pos);
    if (t1 != unknownTile && t1 != tile) {
      return null;
    }
    Tile? t2 = tiles.removeAt(pos);
    if (t2 != unknownTile && t2 != tile) {
      return null;
    }
    TypePile typePile = TypePile(tiles: [t1, t2, tile]);
    touchPiles.add(typePile);

    return typePile;
  }

  /// 检查打牌明杠
  int? checkDiscardBar(Tile tile) {
    int length = tiles.length;
    if (length < 4) {
      return null;
    }
    for (int i = 2; i < tiles.length; ++i) {
      if (tile == tiles[i] && tile == tiles[i - 1] && tile == tiles[i - 2]) {
        return i - 2;
      }
    }

    return null;
  }

  /// 打牌明杠
  TypePile? discardBar(int pos, Tile tile, int discardParticipant) {
    if (pos < 0 || pos >= tiles.length - 2) {
      return null;
    }
    if (tiles[pos] != tile) {
      return null;
    }
    if (tiles[pos + 1] != tile) {
      return null;
    }
    if (tiles[pos + 2] != tile) {
      return null;
    }
    Tile? t1 = tiles.removeAt(pos);
    if (t1 != unknownTile && t1 != tile) {
      return null;
    }
    Tile? t2 = tiles.removeAt(pos);
    if (t2 != unknownTile && t2 != tile) {
      return null;
    }
    Tile? t3 = tiles.removeAt(pos);
    if (t3 != unknownTile && t3 != tile) {
      return null;
    }
    TypePile typePile = TypePile(tiles: [t1, t2, t3, tile]);
    typePile.source = discardParticipant;
    touchPiles.add(typePile);

    return typePile;
  }

  /// 检查摸牌明杠，需要检查tile与碰牌是否相同
  /// 返回的结果包含-1，则drawTile可杠，
  /// 如果包含的数字不是-1，则表示手牌的可杠牌位置
  /// 返回为空，则不可杠
  List<int>? checkDrawBar() {
    if (touchPiles.isEmpty) {
      return null;
    }
    List<int>? results;
    for (int i = 0; i < touchPiles.length; ++i) {
      if (drawTile == touchPiles[i].tiles[0]) {
        return [-1];
      }
    }
    for (int i = 0; i < tiles.length; ++i) {
      var handTile = tiles[i];
      for (int j = 0; j < touchPiles.length; ++j) {
        if (handTile == touchPiles[j].tiles[0]) {
          results ??= [];
          results.add(i);
        }
      }
    }

    return results;
  }

  /// 摸牌明杠：分成摸牌杠牌和手牌杠牌
  /// pos是-1，则drawTile可杠，
  /// pos不是-1，则表示手牌的可杠牌位置
  TypePile? drawBar(int pos, int source, {Tile? tile}) {
    if (pos == -1) {
      if (tile == null) {
        tile ??= drawTile!;
        drawTile = null;
        drawTileType = null;
      }
    } else if (pos > -1 && pos < tiles.length) {
      Tile? t = tiles.removeAt(pos);
      if (t != unknownTile && t != tile) {
        return null;
      }
      tile ??= t;
    } else {
      return null;
    }
    TypePile? typePile;
    for (int i = 0; i < touchPiles.length; ++i) {
      typePile = touchPiles[i];
      if (typePile.tiles[0] == tile) {
        if (typePile.tiles.length < 4) {
          typePile.tiles.add(tile);
          typePile.source = source;
        } else {
          typePile.tiles.removeRange(4, typePile.tiles.length);
        }
      }
    }

    return typePile;
  }

  /// 检查暗杠，就是检查加上摸牌tile后，手上是否有连续的四张，如果有的话返回第一张的位置
  List<int>? checkDarkBar() {
    if (drawTile == null) {
      return null;
    }
    List<Tile> tiles = [...this.tiles];
    tiles.add(drawTile!);
    Pile.sortTile(tiles);
    int length = tiles.length;
    if (length < 4) {
      return null;
    }
    List<int>? pos;
    for (int i = 3; i < length; ++i) {
      if (tiles[i] == tiles[i - 1] &&
          tiles[i] == tiles[i - 2] &&
          tiles[i] == tiles[i - 3]) {
        pos ??= [];
        pos.add(i - 3);
      }
    }

    return pos;
  }

  TypePile? darkBar(int pos, int source) {
    if (drawTile == null || drawTileType == null) {
      return null;
    }
    if (pos < 0 || pos >= tiles.length) {
      return null;
    }

    TypePile? typePile;

    /// 三个手牌相同
    if (tiles[pos] == tiles[pos + 1] && tiles[pos] == tiles[pos + 2]) {
      /// 并且与摸牌相同
      if (tiles[pos] == drawTile) {
        Tile t1 = tiles.removeAt(pos);
        Tile t2 = tiles.removeAt(pos);
        Tile t3 = tiles.removeAt(pos);
        typePile = TypePile(tiles: [t1, t2, t3, drawTile!]);
        typePile.source = source;
        touchPiles.add(typePile);
        drawTile = null;
        drawTileType = null;
      }

      /// 并且与第四张牌相同，摸牌进入手牌
      if (tiles.length > pos + 3 && tiles[pos] == tiles[pos + 3]) {
        Tile t1 = tiles.removeAt(pos);
        Tile t2 = tiles.removeAt(pos);
        Tile t3 = tiles.removeAt(pos);
        Tile t4 = tiles.removeAt(pos);
        if (drawTile != null) {
          tiles.add(drawTile!);
          sort();
        }
        drawTile = null;
        drawTileType = null;
        typePile = TypePile(tiles: [t1, t2, t3, t4]);
        typePile.source = source;
        touchPiles.add(typePile);
      }
    }
    return typePile;
  }

  /// 检查吃牌，tile是上家打出的牌
  List<int>? checkChow(Tile tile) {
    if (tile.suit == Suit.wind) {
      return null;
    }
    int? rank = tile.rank;
    if (rank == null) {
      return null;
    }
    bool success = false;
    Suit suit = tile.suit;
    List<int>? pos;
    for (int i = 0; i < tiles.length; ++i) {
      Tile c = tiles[i];
      if (c.suit != suit) {
        continue;
      }

      success = tile.next(c);
      if (success && i + 1 < tiles.length) {
        Tile c1 = tiles[i + 1];
        success = c.next(c1);
        if (success) {
          pos ??= [];
          pos.add(i);
        }
      }
      success = c.next(tile);
      if (success && i + 1 < tiles.length) {
        Tile c1 = tiles[i + 1];
        success = tile.next(c1);
        if (success) {
          pos ??= [];
          pos.add(i);
        }
      }

      Tile c1 = tiles[i - 1];
      success = c1.next(c1);
      if (success) {
        success = c.next(tile);
        if (success) {
          pos ??= [];
          pos.add(i - 1);
        }
      }
    }

    return pos;
  }

  TypePile chow(int pos, Tile tile) {
    Tile tile1 = tiles.removeAt(pos);
    Tile tile2 = tiles.removeAt(pos);
    TypePile typePile = TypePile(tiles: [tile1, tile2, tile]);
    drawingPiles.add(typePile);

    return typePile;
  }

  /// 检查胡牌，card是自摸或者别人打出的牌，返回是否可能胡的牌
  WinType? checkWin({required Tile tile}) {
    WinType? winType;
    List<Tile> tiles = [...this.tiles];
    tiles.add(tile);
    FormatPile formatPile = FormatPile(tiles: tiles);
    bool success = formatPile.check13_1();
    if (success) {
      winType = WinType.thirteenOne;
    }
    if (winType == null) {
      int count = formatPile.countLux7Pair();
      if (count == 0) {
        winType = WinType.pair7;
      }
      if (count > 0) {
        winType = WinType.luxPair7;
      }
    }

    if (winType == null) {
      success = formatPile.split();
      if (success) {
        formatPile.typePiles.addAll(touchPiles);
        formatPile.typePiles.addAll(drawingPiles);
        winType = formatPile.check();
      }
    }
    if (winType != null) {
      if (winType == WinType.small && drawTile == null) {
        winType = null;
      }
    }

    return winType;
  }

  RoomEventActionResult discard(Tile tile) {
    RoomEventActionResult result = RoomEventActionResult.success;
    Tile? removed = remove(tile);
    if (removed == null) {
      result = RoomEventActionResult.exist;
    }
    if (drawTile != null) {
      tiles.add(drawTile!);
      drawTile = null;
      drawTileType = null;
      sort();
    }

    // logger.i(
    // 'handPile discard tile:$tile result:${result.name}, drawTile is null');

    return result;
  }
}
