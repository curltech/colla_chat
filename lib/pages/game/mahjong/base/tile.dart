import 'dart:ui';

import 'package:colla_chat/pages/game/mahjong/base/full_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

final Tile unknownTile = Tile(-1, Suit.none, windSuit: null);

class Tile {
  static const String mahjongCardPath = 'mahjong/tile/';
  final int id;
  late final Suit suit;
  late final WindSuit? windSuit;
  final int? rank;

  Sprite? sprite;

  Tile(this.id, this.suit, {this.windSuit, this.rank}) {
    check();
  }

  check() {
    if (suit == Suit.none ||
        (suit == Suit.wind && windSuit != null) ||
        (suit != Suit.wind && rank != null)) {
    } else {
      throw 'error tile';
    }
  }

  Tile.fromJson(Map json)
      : id = json['id'],
        rank = json['rank'] {
    String? suit = json['suit'];
    if (suit != null) {
      this.suit = StringUtil.enumFromString(Suit.values, suit) ?? Suit.wind;
    }
    String? windSuit = json['windSuit'];
    if (windSuit != null) {
      this.windSuit =
          StringUtil.enumFromString(WindSuit.values, windSuit) ?? WindSuit.east;
    } else {
      this.windSuit = null;
    }
    sprite = fullPile.tiles[toString()]?.sprite;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'suit': suit.name,
      'windSuit': windSuit?.name,
      'rank': rank,
    };
  }

  loadSprite() async {
    if (suit == Suit.wind && windSuit != null) {
      String path = '$mahjongCardPath${windSuit!.name}.png';
      try {
        Image image =
            await Flame.images.load('$mahjongCardPath${windSuit!.name}.png');
        sprite = Sprite(image);
      } catch (e) {
        logger.e('Flame load image path:$path failure');
      }
    } else {
      if (rank != null) {
        String path = '$mahjongCardPath${suit.name}$rank.png';
        try {
          Image image = await Flame.images.load(path);
          sprite = Sprite(image);
        } catch (e) {
          logger.e('Flame load image path:$path failure');
        }
      }
    }
  }

  String _toString() {
    if (suit == Suit.none) {
      return Suit.none.name;
    } else if (suit == Suit.wind && windSuit != null) {
      return windSuit!.name;
    } else if (rank != null) {
      return '${suit.name}$rank';
    }
    return 'error card';
  }

  @override
  String toString() {
    return '${_toString()}_$id';
  }

  bool is19() {
    return suit == Suit.wind || rank == 1 || rank == 9;
  }

  /// card是否是下一张牌
  bool next(Tile tile) {
    if (suit == tile.suit &&
        rank != null &&
        tile.rank != null &&
        rank! + 1 == tile.rank) {
      return true;
    }

    return false;
  }

  bool gap(Tile tile) {
    if (suit == tile.suit &&
        rank != null &&
        tile.rank != null &&
        rank! + 2 == tile.rank) {
      return true;
    }

    return false;
  }

  @override
  int get hashCode {
    return _toString().hashCode;
  }

  /// 相同的牌，可能id不同
  @override
  bool operator ==(Object other) {
    return _toString() == (other as Tile)._toString();
  }

  /// 同一张牌，id也相同
  bool same(Tile other) {
    return toString() == other.toString();
  }

  Tile copy() {
    Tile c = Tile(id, suit, windSuit: windSuit, rank: rank);
    c.sprite = sprite;

    return c;
  }
}
