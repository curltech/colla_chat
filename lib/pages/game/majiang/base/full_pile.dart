import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/pile.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';

/// 完整的一副麻将
class FullPile extends Pile {
  final Map<String, Card> _cardMap = {};

  FullPile() : super() {
    init();
  }

  init() async {
    for (var windSuit in WindSuit.values) {
      Card card = Card(Suit.wind, windSuit: windSuit);
      cards.add(card);
      _cardMap[card.toString()] = card;
    }
    for (int i = 1; i < 10; ++i) {
      Card card = Card(Suit.suo, rank: i);
      cards.add(card);
      _cardMap[card.toString()] = card;
    }
    for (int i = 1; i < 10; ++i) {
      Card card = Card(Suit.tong, rank: i);
      cards.add(card);
      _cardMap[card.toString()] = card;
    }
    for (int i = 1; i < 10; ++i) {
      Card card = Card(Suit.wan, rank: i);
      cards.add(card);
      _cardMap[card.toString()] = card;
    }
  }

  Card? operator [](String key) {
    return _cardMap[key];
  }
}

/// 原始的麻将牌
final FullPile fullPile = FullPile();
