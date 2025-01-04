import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';

import 'klondike_game.dart';

/// 扑克牌的花色0-3，0方块，1梅花，2红心，3黑桃
@immutable
class Suit {
  factory Suit.fromInt(int index) {
    assert(
      index >= 0 && index <= 3,
      'index is outside of the bounds of what a suit can be',
    );
    return _singletons[index];
  }

  Suit._(this.value, this.label, double x, double y, double w, double h)
      : sprite = klondikeSprite(x, y, w, h);

  final int value;
  final String label;
  final Sprite sprite;

  static final List<Suit> _singletons = [
    Suit._(0, '♦', 973, 14, 177, 182),
    Suit._(1, '♣', 974, 226, 184, 172),
    Suit._(2, '♥', 1176, 17, 172, 183),
    Suit._(3, '♠', 1178, 220, 176, 182),
  ];

  /// Hearts and Diamonds are red, while Clubs and Spades are black.
  bool get isRed => value == 0 || value == 2;

  bool get isBlack => value == 1 || value == 3;
}
