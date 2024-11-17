import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/pile.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';

/// 牌形牌
class TypePile extends Pile {
  late CardType cardType;
  int? source;

  TypePile({super.cards}) {
    cardType = _initCardType();
  }

  /// 多张牌组成的牌形
  CardType _initCardType() {
    sort();
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

/// 经过格式化处理的手牌，被按照花色，牌形进行拆分，用于判断是否胡牌
class FormatPile extends Pile {
  final List<TypePile> typePiles = [];

  FormatPile({super.cards}) {
    sort();
  }

  /// 是否13幺
  bool check13_1() {
    typePiles.clear();
    int length = cards.length;
    if (length != 14) {
      return false;
    }
    for (Card card in cards) {
      if (!card.is19()) {
        return false;
      }
    }
    int count = splitPair();
    if (count != 1) {
      return false;
    }

    return true;
  }

  /// 是否幺9对对胡
  bool check1_9(List<String> cards) {
    for (TypePile typePile in typePiles) {
      if (!typePile.cards[0].is19()) {
        return false;
      }
    }
    return true;
  }

  /// 分拆成对子，返回对子的个数
  int splitPair() {
    int count = 0;
    typePiles.clear();
    for (int i = 0; i < cards.length - 1; i++) {
      Card card = cards[i];
      Card next = cards[i + 1];

      /// 成对，去掉对子将牌
      if (card == next) {
        TypePile pairPile = TypePile(cards: [card, next]);
        typePiles.add(pairPile);
        count++;
        i++;
      }
    }

    return count;
  }

  int splitLux7Pair() {
    int count = splitPair();
    if (count == 7) {
      count = 0;
      for (int i = 0; i < typePiles.length - 1; ++i) {
        TypePile pairPile = typePiles[i];
        TypePile next = typePiles[i + 1];
        if (pairPile.cards[0] == next.cards[0]) {
          count++;
        }
      }
    } else {
      count = -1;
    }

    return count;
  }

  CompleteType? check() {
    bool wind = false; //是否有风牌
    bool oneNine = true; //是否有都是19牌
    bool touch = true; //是否有都是碰或者杠
    bool pure = true; //是否有两种以上的花色
    Suit? previousSuit;
    for (int i = 0; i < typePiles.length; ++i) {
      TypePile typePile = typePiles[i];
      Card card = typePile.cards[0];
      if (!card.is19()) {
        oneNine = false;
      }
      if (typePile.cardType == CardType.straight) {
        touch = false;
      }

      if (card.suit == Suit.wind) {
        wind = true;
      } else if (previousSuit != null) {
        if (previousSuit != card.suit && previousSuit != Suit.wind) {
          pure = false;
        }
      }
      previousSuit = card.suit;
    }
    if (touch) {
      if (oneNine) {
        return CompleteType.oneNine;
      }
      if (pure) {
        if (wind) {
          return CompleteType.mixTouch;
        } else {
          return CompleteType.pureTouch;
        }
      } else {
        return CompleteType.touch;
      }
    } else {
      if (pure) {
        if (wind) {
          return CompleteType.mixOneType;
        } else {
          return CompleteType.pureOneType;
        }
      } else {
        return CompleteType.small;
      }
    }
  }

  bool split() {
    typePiles.clear();
    int length = cards.length;
    if (length == 2 ||
        length == 5 ||
        length == 8 ||
        length == 11 ||
        length == 14) {
      for (int i = 1; i < length; ++i) {
        Card card = cards[i];
        Card previous = cards[i - 1];

        /// 成对，去掉对子将牌
        if (card == previous) {
          List<Card> subCards = cards.sublist(0, i - 1);
          List<Card> cs = cards.sublist(i + 1);
          subCards.addAll(cs);

          /// 对无将牌的牌分类，遍历每种花色
          Map<Suit, List<Card>> suitCardMap = suit(subCards);
          bool success = true;
          typePiles.clear();
          for (var suitEntry in suitCardMap.entries) {
            List<Card> suitCards = suitEntry.value;
            Map<CardType, List<TypePile>>? typePileMap =
                splitTypePile(suitCards);
            // 这种花色没有合适的胡牌组合，说明将牌提取错误
            if (typePileMap == null) {
              success = false;
              typePiles.clear();
              break;
            } else {
              // 找到这种花色胡牌的组合
              for (var entry in typePileMap.entries) {
                List<TypePile> scs = entry.value;
                typePiles.addAll(scs);
              }
            }
          }
          // 找到所有花色胡牌的组合，说明将牌提取正确
          if (success) {
            TypePile typePile = TypePile(cards: [previous, card]);
            typePiles.add(typePile);

            return true;
          }
        }
      }
    }

    return false;
  }

  /// 按照花色牌分类
  Map<Suit, List<Card>> suit(List<Card> cards) {
    Map<Suit, List<Card>> cardMap = {};
    for (int i = 0; i < cards.length; ++i) {
      Card card = cards[i];
      Suit suit = card.suit;
      if (!cardMap.containsKey(suit)) {
        cardMap[suit] = [];
      }
      List<Card> suitCards = cardMap[suit]!;
      suitCards.add(card);
    }

    return cardMap;
  }

  /// 同花色牌形的拆分，其中的一对将牌已经抽出，所以张数只能是3，6，9，12
  Map<CardType, List<TypePile>>? splitTypePile(List<Card> cards) {
    int length = cards.length;
    if (length != 3 && length != 6 && length != 9 && length != 12) {
      return null;
    }
    Map<CardType, List<TypePile>> cardMap = {};
    int mod = length ~/ 3;
    for (int i = 0; i < mod; ++i) {
      int start = i * 3;
      List<Card> subCards = cards.sublist(start, start + 3);
      TypePile typePile = TypePile(cards: subCards);
      if (typePile.cardType != CardType.touch &&
          typePile.cardType != CardType.straight) {
        if (length > start + 3) {
          Card card = cards[start + 3];
          cards[start + 3] = cards[start + 2];
          cards[start + 2] = card;
          subCards = cards.sublist(start, start + 3);
          typePile = TypePile(cards: subCards);
        }
      }
      if (typePile.cardType == CardType.straight ||
          typePile.cardType == CardType.touch) {
        if (!cardMap.containsKey(typePile.cardType)) {
          cardMap[typePile.cardType] = [];
        }
        List<TypePile> cs = cardMap[typePile.cardType]!;
        cs.add(typePile);
      } else {
        return null;
      }
    }

    return cardMap;
  }
}
