enum CardType { wind, suo, tong, wan }

/// 对子,刻子,顺子,杠子
enum SequenceCardType { single, pair, sequence, touch, bar, darkBar }

// 胡牌类型
enum CompleteType {
  thirteenOne, //13幺
  oneNine, //19碰碰胡
  pureTouch, //清碰
  luxPair7, //豪华7对
  pureOneType, //清一色
  mixTouch, //混碰
  pair7, //7对
  mixOneType, //混一色
  touch, //碰碰胡
  small, //小胡
}

enum EnhanceType { lastOne, bar }

class CardUtil {
  static sort(List<String> cards) {
    cards.sort((String a, String b) {
      return a.compareTo(b);
    });
  }

  static CardType cardType(String card) {
    if (card.startsWith(CardType.suo.name)) {
      return CardType.suo;
    } else if (card.startsWith(CardType.tong.name)) {
      return CardType.tong;
    } else if (card.startsWith(CardType.wan.name)) {
      return CardType.wan;
    } else {
      return CardType.wind;
    }
  }

  static int sequence(String card) {
    CardType type = cardType(card);
    if (type != CardType.wind) {
      String seq = card.substring(card.length - 2);

      return int.parse(seq);
    }

    return -1;
  }

  static CardType? sameType(String card0, String card1) {
    CardType type0 = cardType(card0);
    CardType type1 = cardType(card1);
    if (type0 != CardType.wind) {
      if (type0 == type1) {
        return type0;
      }
    }
    return null;
  }

  static bool next(String card0, String card1) {
    CardType? type = sameType(card0, card1);
    if (type != null) {
      int seq0 = sequence(card0);
      int seq1 = sequence(card1);
      if (seq0 + 1 == seq1) {
        return true;
      }
    }
    return false;
  }

  static SequenceCardType sequenceCardType(List<String> cards) {
    if (cards.length == 2 && cards[0] == cards[1]) {
      return SequenceCardType.pair;
    } else if (cards.length == 4 &&
        cards[0] == cards[1] &&
        cards[0] == cards[2] &&
        cards[0] == cards[3]) {
      return SequenceCardType.bar;
    } else if (cards.length == 3 &&
        cards[0] == cards[1] &&
        cards[0] == cards[2]) {
      return SequenceCardType.touch;
    } else if (cards.length == 3 &&
        next(cards[0], cards[1]) &&
        next(cards[1], cards[2])) {
      return SequenceCardType.sequence;
    }

    return SequenceCardType.single;
  }
}
