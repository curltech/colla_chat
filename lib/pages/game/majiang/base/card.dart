import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/suit.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

final Card unknownCard = Card(Suit.none, windSuit: null);

class Card {
  static const String majiangCardPath = 'majiang/card/';

  late final Suit suit;
  late final WindSuit? windSuit;
  final int? rank;

  late final Sprite sprite;

  Card(this.suit, {this.windSuit, this.rank}) {
    check();
    loadSprite();
  }

  check() {
    if (suit == Suit.none ||
        (suit == Suit.wind && windSuit != null) ||
        (suit != Suit.wind && rank != null)) {
    } else {
      throw 'error card';
    }
  }

  Card.fromJson(Map json) : rank = json['rank'] {
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
          await Flame.images.load('$majiangCardPath${windSuit!.name}.png');
      sprite = Sprite(image);
    } else {
      if (rank != null) {
        Image image =
            await Flame.images.load('$majiangCardPath${suit.name}$rank.png');
        sprite = Sprite(image);
      }
    }
  }

  @override
  String toString() {
    if (suit == Suit.wind && windSuit != null) {
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
  bool next(Card card) {
    if (suit == card.suit &&
        rank != null &&
        card.rank != null &&
        rank! + 1 == card.rank) {
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

  Card copy() {
    Card c = Card(suit, windSuit: windSuit, rank: rank);
    c.sprite = sprite;

    return c;
  }
}
