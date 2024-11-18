import 'dart:math';

import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';

/// 一摞麻将牌，可以认为是一个序列的牌
/// 比如每家的手牌和打出的河牌，未发的牌
/// 以及杠牌，碰牌，吃牌
class Pile {
  late final List<Card> cards;

  Pile({List<Card>? cards}) {
    if (cards == null) {
      this.cards = [];
    } else {
      this.cards = [...cards];
    }
  }

  static sortCard(List<Card> cards) {
    cards.sort((Card a, Card b) {
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
    sortCard(cards);
  }

  /// 洗牌
  shuffle([Random? random]) {
    cards.shuffle(random);
  }
}
