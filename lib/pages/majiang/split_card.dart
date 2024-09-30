import 'package:colla_chat/pages/majiang/card.dart';
import 'package:colla_chat/pages/majiang/card_util.dart';
import 'package:flutter/material.dart';

/// 连续牌，代表某个花色的连续牌形，一般只有两张或者三张牌，刻子，顺子或者对子
class SequenceCard {
  final CardType cardType;

  final SequenceCardType sequenceCardType;

  final List<String> cards;

  SequenceCard(this.cardType, this.sequenceCardType, this.cards);

  Widget touchCard({double ratio = 1.0}) {
    List<Widget> children = [];
    for (var card in cards) {
      MajiangCard majiangCard = MajiangCard(card);
      Widget touchCard = majiangCard.touchCard(ratio: ratio);
      children.add(touchCard);
    }
    Widget sequenceCard = Row(
      children: children,
    );

    return sequenceCard;
  }

  Widget previousTouchCard({double ratio = 1.0}) {
    List<Widget> children = [];
    for (var i = 0; i < cards.length; ++i) {
      var card = cards[i];
      MajiangCard majiangCard = MajiangCard(card);
      bool clip = i != cards.length - 1;
      Widget previousTouchCard =
          majiangCard.previousTouchCard(ratio: ratio, clip: clip);
      children.add(previousTouchCard);
    }
    Widget sequenceCard = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    return sequenceCard;
  }

  Widget opponentTouchCard({double ratio = 1.0}) {
    List<Widget> children = [];
    for (var card in cards) {
      MajiangCard majiangCard = MajiangCard(card);
      Widget opponentTouchCard = majiangCard.opponentTouchCard(ratio: ratio);
      children.add(opponentTouchCard);
    }
    Widget sequenceCard = Row(
      children: children,
    );

    return sequenceCard;
  }

  Widget nextTouchCard({double ratio = 1.0}) {
    List<Widget> children = [];
    for (var i = 0; i < cards.length; ++i) {
      var card = cards[i];
      MajiangCard majiangCard = MajiangCard(card);
      bool clip = i != cards.length - 1;
      Widget nextTouchCard =
          majiangCard.nextTouchCard(ratio: ratio, clip: clip);
      children.add(nextTouchCard);
    }
    Widget sequenceCard = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    return sequenceCard;
  }
}

/// 经过拆分的手牌，被按照花色，牌形进行拆分，用于判断是否胡牌
class SplitCard {
  final List<SequenceCard> sequenceCards = [];

  /// 是否13幺
  bool check13_1(List<String> cards) {
    sequenceCards.clear();
    int length = cards.length;
    if (length != 14) {
      return false;
    }
    for (String card in cards) {
      if (!CardConcept.card1_9.contains(card)) {
        return false;
      }
    }
    int count = splitPair(cards);
    if (count != 1) {
      return false;
    }

    return true;
  }

  /// 是否幺9对对胡
  bool check1_9(List<String> cards) {
    for (SequenceCard sequenceCard in sequenceCards) {
      if (!CardConcept.card1_9.contains(sequenceCard.cards[0])) {
        return false;
      }
    }
    return true;
  }

  /// 分拆成对子，返回对子的个数
  int splitPair(List<String> cards) {
    int count = 0;
    sequenceCards.clear();
    for (int i = 0; i < cards.length - 1; i++) {
      String card = cards[i];
      String next = cards[i + 1];

      /// 成对，去掉对子将牌
      if (card == next) {
        CardType cardType = CardUtil.cardType(card);
        SequenceCard doubleSequenceCard =
            SequenceCard(cardType, SequenceCardType.pair, [card, next]);
        sequenceCards.add(doubleSequenceCard);
        count++;
        i++;
      }
    }

    return count;
  }

  int splitLux7Pair(List<String> cards) {
    int count = splitPair(cards);
    if (count == 7) {
      count = 0;
      for (int i = 0; i < sequenceCards.length - 1; ++i) {
        SequenceCard sequenceCard = sequenceCards[i];
        SequenceCard next = sequenceCards[i + 1];
        if (sequenceCard.cards[0] == next.cards[0]) {
          count;
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
    CardType? previousCardType;
    for (int i = 0; i < sequenceCards.length; ++i) {
      SequenceCard sequenceCard = sequenceCards[i];
      String card = sequenceCard.cards[0];
      CardType cardType = sequenceCard.cardType;
      SequenceCardType sequenceCardType = sequenceCard.sequenceCardType;
      if (!CardConcept.card1_9.contains(card)) {
        oneNine = false;
      }
      if (sequenceCardType == SequenceCardType.sequence) {
        touch = false;
      }

      if (cardType == CardType.wind) {
        wind = true;
      } else if (previousCardType != null) {
        if (previousCardType != cardType && previousCardType != CardType.wind) {
          pure = false;
        }
      }
      previousCardType = cardType;
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

  bool split(List<String> cards) {
    sequenceCards.clear();
    int length = cards.length;
    if (length == 2 ||
        length == 5 ||
        length == 8 ||
        length == 11 ||
        length == 14) {
      for (int i = 1; i < length; ++i) {
        String card = cards[i];
        String previous = cards[i - 1];

        /// 成对，去掉对子将牌
        if (card == previous) {
          List<String> subCards = cards.sublist(0, i - 1);
          List<String> cs = cards.sublist(i + 1);
          subCards.addAll(cs);

          /// 对无将牌的牌分类，遍历每种花色
          Map<CardType, List<String>> typeCardMap = splitType(subCards);
          bool success = true;
          sequenceCards.clear();
          for (var typeEntry in typeCardMap.entries) {
            List<String> typeCards = typeEntry.value;
            Map<SequenceCardType, List<SequenceCard>>? sequenceCardMap =
                _split(typeCards);
            // 这种花色没有合适的胡牌组合，说明将牌提取错误
            if (sequenceCardMap == null) {
              success = false;
              sequenceCards.clear();
              break;
            } else {
              // 找到这种花色胡牌的组合
              for (var entry in sequenceCardMap.entries) {
                List<SequenceCard> scs = entry.value;
                sequenceCards.addAll(scs);
              }
            }
          }
          // 找到所有花色胡牌的组合，说明将牌提取正确
          if (success) {
            CardType cardType = CardUtil.cardType(previous);
            SequenceCard doubleSequenceCard =
                SequenceCard(cardType, SequenceCardType.pair, [previous, card]);
            sequenceCards.add(doubleSequenceCard);

            return true;
          }
        }
      }
    }

    return false;
  }

  /// 对无将牌的牌分类
  Map<CardType, List<String>> splitType(List<String> cards) {
    Map<CardType, List<String>> cardMap = {};
    for (int i = 0; i < cards.length; ++i) {
      String card = cards[i];
      CardType cardType = CardUtil.cardType(card);
      if (!cardMap.containsKey(cardType)) {
        cardMap[cardType] = [];
      }
      List<String> typeCards = cardMap[cardType]!;
      typeCards.add(card);
    }

    return cardMap;
  }

  /// 同花色类型的拆分，其中的一对将牌已经抽出，所以张数只能是3，6，9，12
  Map<SequenceCardType, List<SequenceCard>>? _split(List<String> cards) {
    int length = cards.length;
    if (length != 3 && length != 6 && length != 9 && length != 12) {
      return null;
    }

    CardType cardType = CardUtil.cardType(cards[0]);
    Map<SequenceCardType, List<SequenceCard>> cardMap = {};
    int mod = length ~/ 3;
    for (int i = 0; i < mod; ++i) {
      int start = i * mod;
      List<String> subCards = cards.sublist(start, start + 3);
      SequenceCardType sequenceCardType = CardUtil.sequenceCardType(subCards);
      if (sequenceCardType != SequenceCardType.touch &&
          sequenceCardType != SequenceCardType.sequence) {
        if (length > start + 3) {
          String card = cards[start + 3];
          cards[start + 3] = cards[start + 2];
          cards[start + 2] = card;
          subCards = cards.sublist(start, start + 3);
          sequenceCardType = CardUtil.sequenceCardType(subCards);
        }
      }
      if (sequenceCardType == SequenceCardType.sequence ||
          sequenceCardType == SequenceCardType.touch) {
        if (!cardMap.containsKey(sequenceCardType)) {
          cardMap[sequenceCardType] = [];
        }
        List<SequenceCard> cs = cardMap[sequenceCardType]!;
        cs.add(SequenceCard(cardType, sequenceCardType, cards));
      } else {
        return null;
      }
    }

    return cardMap;
  }
}
