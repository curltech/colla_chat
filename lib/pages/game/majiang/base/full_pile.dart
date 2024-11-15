import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/pile.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';

/// 完整的一副麻将
class FullPile extends Pile {
  FullPile() {
    init();
  }

  init() async {
    for (int i = 0; i < 4; ++i) {
      for (var windSuit in WindSuit.values) {
        Card card = Card(Suit.wind, windSuit: windSuit);
        cards.add(card);
      }
      for (int i = 1; i < 10; ++i) {
        Card card = Card(Suit.suo, rank: i);
        cards.add(card);
      }
      for (int i = 1; i < 10; ++i) {
        Card card = Card(Suit.tong, rank: i);
        cards.add(card);
      }
      for (int i = 1; i < 10; ++i) {
        Card card = Card(Suit.wan, rank: i);
        cards.add(card);
      }
    }
  }
}
