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

  /// 排序
  sort() {
    cards.sort((Card a, Card b) {
      return a.toString().compareTo(b.toString());
    });
  }

  /// 洗牌
  shuffle([Random? random]) {
    cards.shuffle(random);
  }
}
