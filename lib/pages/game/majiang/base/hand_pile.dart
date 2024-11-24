import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/format_card.dart';
import 'package:colla_chat/pages/game/majiang/base/pile.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';

/// 正在使用的牌，手牌
class HandPile extends Pile {
  //碰，杠牌，吃牌
  final List<TypePile> touchPiles = [];

  final List<TypePile> drawingPiles = [];

  /// 刚摸进的牌
  Card? takeCard;

  TakeCardType? takeCardType;

  HandPile({super.cards});

  /// 检查碰牌
  int? checkTouch(Card card) {
    int length = cards.length;
    if (length < 2) {
      return null;
    }
    for (int i = 1; i < cards.length; ++i) {
      if (card == cards[i] && card == cards[i - 1]) {
        return i - 1;
      }
    }

    return null;
  }

  bool touch(int pos, Card card) {
    if (cards[pos] != card || cards[pos + 1] != card) {
      return false;
    }
    cards.removeAt(pos);
    cards.removeAt(pos);
    touchPiles.add(TypePile(cards: [card, card, card]));

    return true;
  }

  /// 检查打牌明杠
  int? checkSendBar(Card card) {
    int length = cards.length;
    if (length < 4) {
      return null;
    }
    for (int i = 2; i < cards.length; ++i) {
      if (card == cards[i] && card == cards[i - 1] && card == cards[i - 2]) {
        return i - 2;
      }
    }

    return null;
  }

  /// 打牌明杠
  Card? sendBar(int pos, Card card, int sender) {
    if (cards[pos] != card) {
      return null;
    }
    card = cards.removeAt(pos);
    cards.removeAt(pos);
    cards.removeAt(pos);
    TypePile typePile = TypePile(cards: [card, card, card, card]);
    typePile.source = sender;
    touchPiles.add(typePile);

    return card;
  }

  /// 检查摸牌明杠，需要检查card与碰牌是否相同
  /// 返回的结果包含-1，则takeCard可杠，
  /// 如果包含的数字不是-1，则表示手牌的可杠牌位置
  /// 返回为空，则不可杠
  List<int>? checkTakeBar() {
    if (touchPiles.isEmpty) {
      return null;
    }
    List<int>? results;
    for (int i = 0; i < touchPiles.length; ++i) {
      if (takeCard?.toString() == touchPiles[i].cards[0].toString()) {
        return [-1];
      }
    }
    for (int i = 0; i < cards.length; ++i) {
      var handCard = cards[i];
      for (int j = 0; j < touchPiles.length; ++j) {
        if (handCard.toString() == touchPiles[j].cards[0].toString()) {
          results ??= [];
          results.add(i);
        }
      }
    }

    return results;
  }

  /// 摸牌明杠：分成摸牌杠牌和手牌杠牌
  /// pos是-1，则takeCard可杠，
  /// pos不是-1，则表示手牌的可杠牌位置
  Card? takeBar(int pos, int source) {
    Card card;
    if (pos == -1) {
      card = takeCard!;
    } else {
      card = cards.removeAt(pos);
    }

    takeCard = null;
    takeCardType = null;
    for (int i = 0; i < touchPiles.length; ++i) {
      TypePile typePile = touchPiles[i];
      if (typePile.cards[0] == card) {
        if (typePile.cards.length < 4) {
          typePile.cards.add(card);
          typePile.source = source;

          return card;
        } else {
          typePile.cards.removeRange(4, typePile.cards.length);
        }
      }
    }

    return null;
  }

  /// 检查暗杠，就是检查加上摸牌card后，手上是否有连续的四张，如果有的话返回第一张的位置
  List<int>? checkDarkBar() {
    if (takeCard == null) {
      return null;
    }
    List<Card> cards = [...this.cards];
    cards.add(takeCard!);
    Pile.sortCard(cards);
    int length = cards.length;
    if (length < 4) {
      return null;
    }
    List<int>? pos;
    for (int i = 3; i < length; ++i) {
      if (cards[i] == cards[i - 1] &&
          cards[i] == cards[i - 2] &&
          cards[i] == cards[i - 3]) {
        pos ??= [];
        pos.add(i - 3);
      }
    }

    return pos;
  }

  Card? darkBar(int pos, int source) {
    Card? card;

    /// 三个手牌相同
    if (cards[pos] == cards[pos + 1] && cards[pos] == cards[pos + 2]) {
      /// 并且与摸牌相同
      if (cards[pos] == takeCard) {
        card = cards.removeAt(pos);
        cards.removeAt(pos);
        cards.removeAt(pos);
        takeCard = null;
        takeCardType = null;
        TypePile typePile = TypePile(cards: [card, card, card, card]);
        typePile.source = source;
        touchPiles.add(typePile);
      }

      /// 并且与第四张牌相同，摸牌进入手牌
      if (cards.length > pos + 3 && cards[pos] == cards[pos + 3]) {
        card = cards.removeAt(pos);
        cards.removeAt(pos);
        cards.removeAt(pos);
        cards.removeAt(pos);
        if (takeCard != null) {
          cards.add(takeCard!);
          sort();
        }
        takeCard = null;
        takeCardType = null;
        TypePile typePile = TypePile(cards: [card, card, card, card]);
        typePile.source = source;
        touchPiles.add(typePile);
      }
    }
    return card;
  }

  /// 检查吃牌，card是上家打出的牌
  List<int>? checkDrawing(Card card) {
    if (card.suit == Suit.wind) {
      return null;
    }
    int? rank = card.rank;
    if (rank == null) {
      return null;
    }
    bool success = false;
    Suit suit = card.suit;
    List<int>? pos;
    for (int i = 0; i < cards.length; ++i) {
      Card c = cards[i];
      if (c.suit != suit) {
        continue;
      }

      success = card.next(c);
      if (success && i + 1 < cards.length) {
        Card c1 = cards[i + 1];
        success = c.next(c1);
        if (success) {
          pos ??= [];
          pos.add(i);
        }
      }
      success = c.next(card);
      if (success && i + 1 < cards.length) {
        Card c1 = cards[i + 1];
        success = card.next(c1);
        if (success) {
          pos ??= [];
          pos.add(i);
        }
      }

      Card c1 = cards[i - 1];
      success = c1.next(c1);
      if (success) {
        success = c.next(card);
        if (success) {
          pos ??= [];
          pos.add(i - 1);
        }
      }
    }

    return pos;
  }

  drawing(int pos, Card card) {
    Card card1 = cards.removeAt(pos);
    Card card2 = cards.removeAt(pos);
    TypePile typePile = TypePile(cards: [card1, card2, card]);
    drawingPiles.add(typePile);
  }

  /// 检查胡牌，card是自摸或者别人打出的牌，返回是否可能胡的牌
  CompleteType? checkComplete({Card? card}) {
    CompleteType? completeType;
    List<Card> cards = [...this.cards];
    if (card != null) {
      cards.add(card);
    }
    FormatPile formatPile = FormatPile(cards: cards);
    bool success = formatPile.check13_1();
    if (success) {
      completeType = CompleteType.thirteenOne;
    }
    if (completeType == null) {
      int count = formatPile.splitLux7Pair();
      if (count == 0) {
        completeType = CompleteType.pair7;
      }
      if (count > 0) {
        completeType = CompleteType.luxPair7;
      }
    }

    if (completeType == null) {
      success = formatPile.split();
      if (success) {
        formatPile.typePiles.addAll(touchPiles);
        formatPile.typePiles.addAll(drawingPiles);
        completeType = formatPile.check();
      }
    }
    if (completeType != null) {
      if (completeType == CompleteType.small && takeCard == null) {
        completeType = null;
      }
    }

    return completeType;
  }

  bool send(Card card) {
    bool success = false;
    if (card == takeCard) {
      success = true;
    } else {
      success = cards.remove(card);
      if (takeCard != null) {
        cards.add(takeCard!);
        sort();
      }
    }
    takeCard = null;
    takeCardType = null;

    return success;
  }
}
