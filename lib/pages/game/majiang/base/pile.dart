import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';

/// 一摞麻将牌，可以认为是一个序列的牌
/// 比如每家的手牌和打出的河牌，未发的牌
/// 以及杠牌，碰牌，吃牌
class Pile {
  List<Card> cards = [];

  /// 排序
  sort() {
    cards.sort((Card a, Card b) {
      return a.toString().compareTo(b.toString());
    });
  }

  /// 洗牌
  shuffle() {
    cards.shuffle();
  }

  /// 多张牌组成的牌形
  CardType cardType() {
    if (cards.length == 2 && cards[0] == cards[1]) {
      return CardType.pair;
    } else if (cards.length == 4 &&
        cards[0] == cards[1] &&
        cards[0] == cards[2] &&
        cards[0] == cards[3]) {
      return CardType.bar;
    } else if (cards.length == 3 &&
        cards[0] == cards[1] &&
        cards[0] == cards[2]) {
      return CardType.touch;
    } else if (cards.length == 3 &&
        cards[0].next(cards[1]) &&
        cards[1].next(cards[2])) {
      return CardType.straight;
    }

    return CardType.single;
  }
}
