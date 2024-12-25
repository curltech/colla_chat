import 'dart:ui';

import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

final Tile unknownTile = Tile(Suit.none, windSuit: null);

class Tile {
  static const String mahjongCardPath = 'mahjong/tile/';

  late final Suit suit;
  late final WindSuit? windSuit;
  final int? rank;

  late final Sprite sprite;

  Tile(this.suit, {this.windSuit, this.rank}) {
    check();
    loadSprite();
  }

  check() {
    if (suit == Suit.none ||
        (suit == Suit.wind && windSuit != null) ||
        (suit != Suit.wind && rank != null)) {
    } else {
      throw 'error tile';
    }
  }

  Tile.fromJson(Map json) : rank = json['rank'] {
    String? suit = json['suit'];
    if (suit != null) {
      this.suit = StringUtil.enumFromString(Suit.values, suit) ?? Suit.wind;
    }
    String? windSuit = json['windSuit'];
    if (windSuit != null) {
      this.windSuit =
          StringUtil.enumFromString(WindSuit.values, windSuit) ?? WindSuit.east;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'suit': suit.name,
      'windSuit': windSuit?.name,
      'rank': rank,
    };
  }

  loadSprite() async {
    if (suit == Suit.wind && windSuit != null) {
      Image image =
          await Flame.images.load('$mahjongCardPath${windSuit!.name}.png');
      sprite = Sprite(image);
    } else {
      if (rank != null) {
        Image image =
            await Flame.images.load('$mahjongCardPath${suit.name}$rank.png');
        sprite = Sprite(image);
      }
    }
  }

  @override
  String toString() {
    if (suit == Suit.none) {
      return Suit.none.name;
    } else if (suit == Suit.wind && windSuit != null) {
      return windSuit!.name;
    } else if (rank != null) {
      return '${suit.name}$rank';
    }
    return 'error card';
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

  @override
  int get hashCode {
    return toString().hashCode;
  }

  @override
  bool operator ==(Object other) {
    return toString() == other.toString();
  }

  Tile copy() {
    Tile c = Tile(suit, windSuit: windSuit, rank: rank);
    c.sprite = sprite;

    return c;
  }
}
