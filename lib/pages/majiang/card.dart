import 'dart:math';

import 'package:align_positioned/align_positioned.dart';
import 'package:colla_chat/pages/majiang/card_util.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CardConcept {
  static const String majiangCardPath = 'assets/images/majiang/card/';
  static const List<String> windImageFiles = [
    '11_east',
    '12_south',
    '13_west',
    '14_north',
    '15_center',
    '16_fortune',
    '17_whiteboard',
  ];
  static const String suoImageFile = 'suo';
  static const String tongImageFile = 'tong';
  static const String wanImageFile = 'wan';
  static const List<String> card1_9 = [
    'suo1',
    'suo9',
    'tong1',
    'tong9',
    'wan1',
    'wan9',
    'east',
    'south',
    'west',
    'north',
    'center',
    'fortune',
    'whiteboard',
  ];

  late final List<String> allCards;

  final windImages = <String, Widget>{};
  final suoImages = <String, Widget>{};
  final tongImages = <String, Widget>{};
  final wanImages = <String, Widget>{};

  CardConcept() {
    _load();
  }

  _load() {
    for (int i = 0; i < windImageFiles.length; ++i) {
      var image = Image.asset(
        '$majiangCardPath${windImageFiles[i]}.png',
        fit: BoxFit.cover,
      );
      String name = windImageFiles[i];
      windImages[name] = image;
    }
    for (int i = 1; i < 10; ++i) {
      var image = Image.asset(
        '$majiangCardPath$suoImageFile$i.png',
        fit: BoxFit.cover,
      );
      suoImages['$suoImageFile$i'] = image;
    }
    for (int i = 1; i < 10; ++i) {
      var image = Image.asset(
        '$majiangCardPath$tongImageFile$i.png',
        fit: BoxFit.cover,
      );
      tongImages['$tongImageFile$i'] = image;
    }
    for (int i = 1; i < 10; ++i) {
      var image = Image.asset(
        '$majiangCardPath$wanImageFile$i.png',
        fit: BoxFit.cover,
      );
      wanImages['$wanImageFile$i'] = image;
    }

    allCards = [
      ...windImages.keys,
      ...suoImages.keys,
      ...tongImages.keys,
      ...wanImages.keys,
      ...windImages.keys,
      ...suoImages.keys,
      ...tongImages.keys,
      ...wanImages.keys,
      ...windImages.keys,
      ...suoImages.keys,
      ...tongImages.keys,
      ...wanImages.keys,
      ...windImages.keys,
      ...suoImages.keys,
      ...tongImages.keys,
      ...wanImages.keys,
    ];
  }

  Widget? get(String name) {
    Widget? image = windImages[name];
    image ??= suoImages[name];
    image ??= tongImages[name];
    image ??= wanImages[name];

    return image;
  }
}

final CardConcept cardConcept = CardConcept();

class BackgroundImage {
  static const String majiangPath = 'assets/images/majiang/';
  static const List<String> backgroundImageFiles = [
    'background', //桌面
    'barcard', //暗杠
    'handcard', //自己手牌
    'opponentbar', //对家暗杠
    'opponenthand', //对家手牌
    'poolcard', //自己河牌
    'sidebar', //边家暗杠
    'sidecard', // 边家出牌
    'sidehand', // 边家手牌
    'touchcard' // 自己碰牌
  ];

  final backgroundImages = <String, Widget>{};

  BackgroundImage() {
    _load();
  }

  _load() {
    for (int i = 0; i < backgroundImageFiles.length; ++i) {
      var image = Image.asset(
        '$majiangPath${backgroundImageFiles[i]}.webp',
        fit: BoxFit.cover,
      );

      backgroundImages[backgroundImageFiles[i]] = image;
    }
  }

  Widget? get(String name) {
    Widget? image = backgroundImages[name];

    return image;
  }
}

final BackgroundImage backgroundImage = BackgroundImage();

/// 单张麻将牌
class MajiangCard {
  final String name;

  MajiangCard(this.name);

  ///自己的手牌
  Widget handCard({double ratio = 1.0}) {
    return SizedBox(
        width: 75.0 * ratio,
        height: 110.0 * ratio,
        child: Stack(
          children: [
            backgroundImage.get('handcard')!,
            AlignPositioned(
              alignment: Alignment.topLeft,
              dx: 0.0,
              dy: 4.0 * ratio,
              touch: Touch.inside,
              child: cardConcept.get(name)!,
            ),
          ],
        ));
  }

  /// 自己的河牌，碰牌或者杠牌
  Widget touchCard({double ratio = 1.0}) {
    return SizedBox(
        width: 44.0 * ratio,
        height: 66.0 * ratio,
        child: Stack(
          children: [
            backgroundImage.get('touchcard')!,
            AlignPositioned(
              alignment: Alignment.topLeft,
              dx: 0.0,
              dy: -8.0 * ratio,
              touch: Touch.inside,
              child: cardConcept.get(name)!,
            ),
          ],
        ));
  }

  /// 对家的手牌
  Widget opponentHand({double ratio = 1.0}) {
    return SizedBox(
        width: 38.0 * ratio,
        height: 54.0 * ratio,
        child: backgroundImage.get('opponenthand')!);
  }

  /// 对家的河牌，碰牌或者杠牌
  Widget opponentTouchCard({double ratio = 1.0}) {
    return SizedBox(
        width: 44.0 * ratio,
        height: 66.0 * ratio,
        child: Stack(
          children: [
            backgroundImage.get('touchcard')!,
            AlignPositioned(
              alignment: Alignment.topLeft,
              dx: 0.0,
              dy: -8.0 * ratio,
              touch: Touch.inside,
              child: RotatedBox(quarterTurns: 1, child: cardConcept.get(name)!),
            ),
          ],
        ));
  }

  /// 下家的手牌
  Widget nextHand({double ratio = 1.0, bool clip = true}) {
    Widget clipWidget = backgroundImage.get('sidehand')!;
    if (clip) {
      clipWidget = ClipRect(
          child: Align(
              alignment: Alignment.topLeft,
              heightFactor: 0.55,
              child: clipWidget));
    }

    return SizedBox(width: 22.0 * ratio, child: clipWidget);
  }

  /// 下家的河牌
  Widget nextTouchCard({double ratio = 1.0}) {
    return SizedBox(
        width: 47.0 * ratio,
        height: 43.0 * ratio,
        child: Stack(
          children: [
            backgroundImage.get('sidecard')!,
            AlignPositioned(
              alignment: Alignment.topLeft,
              dx: 0.0,
              dy: -8.0 * ratio,
              touch: Touch.inside,
              child: RotatedBox(quarterTurns: 1, child: cardConcept.get(name)!),
            ),
          ],
        ));
  }

  /// 上家的手牌
  Widget previousHand({double ratio = 1.0, bool clip = true}) {
    Widget clipWidget =
        RotatedBox(quarterTurns: 2, child: backgroundImage.get('sidehand')!);
    if (clip) {
      clipWidget = ClipRect(
          child: Align(
              alignment: Alignment.topLeft,
              heightFactor: 0.55,
              child: clipWidget));
    }
    return SizedBox(width: 22.0 * ratio, child: clipWidget);
  }

  /// 上家的河牌
  Widget previousTouchCard({double ratio = 1.0}) {
    return SizedBox(
        width: 47.0 * ratio,
        height: 43.0 * ratio,
        child: Stack(
          children: [
            backgroundImage.get('sidecard')!,
            AlignPositioned(
              alignment: Alignment.topLeft,
              dx: 0.0,
              dy: -8.0 * ratio,
              touch: Touch.inside,
              child:
                  RotatedBox(quarterTurns: -1, child: cardConcept.get(name)!),
            ),
          ],
        ));
  }
}

/// 连续牌，代表某个花色的连续牌形，一般只有两张或者三张牌，刻子，顺子或者对子
class SequenceCard {
  final CardType cardType;

  final SequenceCardType sequenceCardType;

  final List<String> cards;

  SequenceCard(this.cardType, this.sequenceCardType, this.cards);
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
    for (int i = 0; i < cards.length; i++) {
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
          subCards.addAll(cards.sublist(i));

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
                List<SequenceCard> sequenceCards = entry.value;
                sequenceCards.addAll(sequenceCards);
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
    int start = 0;
    for (int i = 1; i < cards.length; ++i) {
      String card = cards[i];
      String previous = cards[i - 1];
      CardType? cardType = CardUtil.sameType(previous, card);
      if (cardType == null) {
        cardType = CardUtil.cardType(previous);
        if (!cardMap.containsKey(cardType)) {
          cardMap[cardType] = [];
        }
        List<String> typeCards = cardMap[cardType]!;
        typeCards.addAll(cards.sublist(start, i));
        start = i;
      }
    }

    return cardMap;
  }

  /// 同花色类型的拆分，其中的一对将牌已经抽出，所以张数只能是3，6，9，12
  Map<SequenceCardType, List<SequenceCard>>? _split(List<String> cards) {
    int length = cards.length;
    if (length != 3 || length != 6 || length != 9 || length != 12) {
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
          String card = subCards[start + 3];
          subCards[start + 3] = subCards[start + 2];
          subCards[start + 2] = card;
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

enum ParticipantStatus { touch, bar, darkbar, drawing, complete }

class ParticipantCard {
  final String peerId;

  ///是否是机器人
  final bool robot;

  //手牌
  final RxList<String> handCards = <String>[].obs;

  //碰，杠牌，吃牌
  final RxList<SequenceCard> touchCards = <SequenceCard>[].obs;

  final RxList<SequenceCard> drawingCards = <SequenceCard>[].obs;

  //打出的牌
  final RxList<String> poolCards = <String>[].obs;

  final Rx<String?> comingCard = Rx<String?>(null);

  final RxList<ParticipantStatus> status = RxList<ParticipantStatus>([]);

  ParticipantCard(this.peerId, {this.robot = false});

  clear() {
    handCards.clear();
    touchCards.clear();
    drawingCards.clear();
    poolCards.clear();
  }

  /// 排序
  handSort() {
    CardUtil.sort(handCards);
  }

  List<String> get allTouchCards {
    List<String> cards = [];
    for (SequenceCard touchCard in touchCards.value) {
      cards.addAll(touchCard.cards);
    }

    return cards;
  }

  List<String> get allDrawingCards {
    List<String> cards = [];
    for (SequenceCard drawingCard in drawingCards.value) {
      cards.addAll(drawingCard.cards);
    }

    return cards;
  }

  /// 检查明杠
  int checkBar(String card) {
    int length = handCards.length;
    if (length < 4) {
      return -1;
    }
    for (int i = 2; i < handCards.length; ++i) {
      if (card == handCards[i] &&
          card == handCards[i - 1] &&
          card == handCards[i - 2]) {
        return i - 2;
      }
    }

    return -1;
  }

  /// 检查暗杠
  List<int>? checkDarkBar({String? card}) {
    int length = handCards.length;
    if (length < 4) {
      return null;
    }
    List<int>? pos;
    if (card != null) {
      for (int i = 2; i < handCards.length; ++i) {
        if (card == handCards[i] &&
            handCards[i] == handCards[i - 1] &&
            handCards[i] == handCards[i - 2]) {
          pos ??= [];
          pos.add(i - 2);
        }
      }
    } else {
      for (int i = 3; i < handCards.length; ++i) {
        if (handCards[i] == handCards[i - 1] &&
            handCards[i] == handCards[i - 2] &&
            handCards[i] == handCards[i - 3]) {
          pos ??= [];
          pos.add(i - 3);
        }
      }
    }

    return pos;
  }

  /// 检查碰牌
  int checkTouch(String card) {
    int length = handCards.length;
    if (length < 2) {
      return -1;
    }
    for (int i = 1; i < handCards.length; ++i) {
      if (card == handCards[i] && card == handCards[i - 1]) {
        return i - 1;
      }
    }

    return -1;
  }

  /// 检查吃牌
  bool checkDrawing(String card) {
    if (!(card.startsWith('suo') ||
        card.startsWith('tong') ||
        card.startsWith('wan'))) {
      return false;
    }
    String flag = card.substring(0, card.length - 2);
    int pos = int.parse(card.substring(card.length - 1));
    String card1;
    String card2;
    if (pos == 9) {
      card1 = '${flag}7';
      card2 = '${flag}8';
      if (handCards.contains(card1) && handCards.contains(card2)) {
        return true;
      }
    } else if (pos == 8) {
      card1 = '${flag}7';
      card2 = '${flag}9';
      if (handCards.contains(card1) && handCards.contains(card2)) {
        return true;
      }
    } else if (pos == 1) {
      card1 = '${flag}2';
      card2 = '${flag}3';
    } else if (pos == 2) {
      card1 = '${flag}1';
      card2 = '${flag}3';
      if (handCards.contains(card1) && handCards.contains(card2)) {
        return true;
      }
    } else {
      card1 = '$flag${pos - 1}';
      card2 = '$flag${pos + 1}';
      if (handCards.contains(card1) && handCards.contains(card2)) {
        return true;
      }
      card1 = '$flag${pos + 1}';
      card2 = '$flag${pos + 2}';
      if (handCards.contains(card1) && handCards.contains(card2)) {
        return true;
      }
      card1 = '$flag${pos - 1}';
      card2 = '$flag${pos - 2}';
      if (handCards.contains(card1) && handCards.contains(card2)) {
        return true;
      }
    }

    return false;
  }

  /// 检查胡牌
  CompleteType? checkComplete(String card) {
    List<String> cards = [...handCards];
    cards.add(card);
    SplitCard splitCard = SplitCard();
    bool success = splitCard.check13_1(cards);
    if (success) {
      return CompleteType.thirteenOne;
    }
    int count = splitCard.splitLux7Pair(cards);
    if (count == 0) {
      return CompleteType.pair7;
    }
    if (count > 0) {
      return CompleteType.luxPair7;
    }

    success = splitCard.split(cards);
    if (success) {
      splitCard.sequenceCards.addAll(touchCards);
      splitCard.sequenceCards.addAll(drawingCards);
      CompleteType? completeType = splitCard.check();

      return completeType;
    }

    return null;
  }

  /// 检查上家打出的牌是否可以吃牌
  drawingCheck(String card) {
    List<ParticipantStatus> participantStatus = [];
    if (checkDrawing(card)) {
      participantStatus.add(ParticipantStatus.drawing);
    }

    status.assignAll(participantStatus);
  }

  /// 检查别人打出的牌是否可以杠牌，碰牌和胡牌
  sendCheck(String card) {
    List<ParticipantStatus> participantStatus = [];
    if (checkBar(card) > -1) {
      participantStatus.add(ParticipantStatus.bar);
    }
    if (checkTouch(card) > -1) {
      participantStatus.add(ParticipantStatus.touch);
    }
    if (checkComplete(card) != null) {
      participantStatus.add(ParticipantStatus.complete);
    }

    status.assignAll(participantStatus);
  }

  /// 检查发牌是否可以暗杠牌和胡牌
  takeCheck(String card) {
    List<ParticipantStatus> participantStatus = [];
    if (checkDarkBar(card: card) != null) {
      participantStatus.add(ParticipantStatus.darkbar);
    }
    if (checkDarkBar() != null) {
      participantStatus.add(ParticipantStatus.darkbar);
    }
    if (checkComplete(card) != null) {
      participantStatus.add(ParticipantStatus.complete);
    }

    status.assignAll(participantStatus);
  }

  /// 打牌
  send(String card) {
    if (card != comingCard.value) {
      handCards.remove(card);
    } else {
      comingCard.value = null;
    }

    poolCards.add(card);
  }

  /// 碰牌
  touch(String card) {
    handCards.remove(card);
    handCards.remove(card);
    SequenceCard sequenceCard = SequenceCard(
        CardUtil.cardType(card), SequenceCardType.touch, [card, card, card]);
    touchCards.add(sequenceCard);
  }

  /// 明杠牌
  bar(String card) {
    handCards.remove(card);
    handCards.remove(card);
    handCards.remove(card);
    SequenceCard sequenceCard = SequenceCard(CardUtil.cardType(card),
        SequenceCardType.bar, [card, card, card, card]);
    touchCards.add(sequenceCard);
  }

  /// 暗杠牌
  darkBar(String card) {
    handCards.remove(card);
    handCards.remove(card);
    handCards.remove(card);
    handCards.remove(card);
    SequenceCard sequenceCard = SequenceCard(CardUtil.cardType(card),
        SequenceCardType.darkBar, [card, card, card, card]);
    touchCards.add(sequenceCard);
  }

  /// 过牌
  pass() {
    status.clear();
  }

  /// 摸牌，peerId为空，自己摸牌，不为空，别人摸牌
  take(String card) {
    comingCard.value = card;
    takeCheck(card);
  }
}

/// 麻将房间
class MajiangRoom {
  final String name;

  /// 四个参与者的牌，在所有的参与者电脑中都保持一致，所以当前参与者的位置是不固定的
  final List<ParticipantCard> participantCards = [];

  /// 未知的牌
  List<String> unknownCards = [];

  /// 庄家
  int? host;

  /// 当前的持有发牌的参与者
  int? keeper;

  /// 刚出牌的参与者
  int? sender;

  /// 正在等待做出决定的参与者，如果为空，则房间发牌，
  /// 如果都是pass消解等待的，则发牌，有一家是非pass消解的不发牌
  List<int> waiting = [];

  MajiangRoom(this.name, List<String> peerIds) {
    _init(peerIds);
  }

  /// 加参与者，第一个是自己，第二个是下家，第三个是对家，第四个是上家
  _init(List<String> peerIds) {
    for (var peerId in peerIds) {
      participantCards.add(ParticipantCard(peerId));
    }
    if (peerIds.length < 4) {
      for (int i = 0; i < 4 - peerIds.length; i++) {
        ParticipantCard participantCard =
            ParticipantCard('robot$i', robot: true);
        participantCards.add(participantCard);
      }
    }
  }

  int? get(String peerId) {
    for (int i = 0; i < participantCards.length; i++) {
      ParticipantCard participantCard = participantCards[i];
      if (participantCard.peerId == peerId) {
        return i;
      }
    }
    return null;
  }

  /// 自己的位置
  int get me {
    int? pos = get(myself.peerId!);
    if (pos == null) {
      throw 'No me';
    }
    return pos;
  }

  /// 下家
  int next(int pos) {
    if (pos == participantCards.length - 1) {
      return 0;
    }
    return pos + 1;
  }

  /// 上家
  int previous(int pos) {
    if (pos == 0) {
      return participantCards.length - 1;
    }
    return pos - 1;
  }

  /// 对家
  int opponent(int pos) {
    if (pos == 0) {
      return 2;
    }
    if (pos == 1) {
      return 3;
    }
    if (pos == 2) {
      return 0;
    }
    if (pos == 3) {
      return 1;
    }
    throw 'error position';
  }

  /// 新玩一局，positions为空自己发牌，不为空，别人发牌
  List<int> play({String? host, List<int>? positions}) {
    for (var participantCard in participantCards) {
      participantCard.clear();
    }
    unknownCards.clear();
    this.host = null;
    keeper = null;
    List<String> allCards = [...cardConcept.allCards];
    Random random = Random.secure();
    positions ??= [];
    for (int i = 0; i < 136; ++i) {
      int pos;
      if (i < positions.length) {
        pos = positions[i];
      } else {
        pos = random.nextInt(allCards.length);
        positions.add(pos);
      }
      String card = allCards.removeAt(pos);
      if (i < 53) {
        int reminder = i % 4;
        participantCards[reminder].handCards.add(card);
      } else {
        unknownCards.add(card);
      }
    }

    /// 自己的牌现排序
    int pos = me;
    participantCards[pos].handSort();

    /// 如果没有指定庄家，自己就是庄家，否则设定庄家
    if (host == null) {
      this.host = pos;
      keeper = this.host;
    } else {
      int? pos = get(host);
      if (pos != null) {
        this.host = pos;
        keeper = this.host;
      }
    }

    return positions;
  }

  /// 打牌
  send(int pos, String card) {
    participantCards[pos].send(card);
    sender = pos;
    keeper = null;
  }

  /// 发牌
  take(int pos) {
    String card = unknownCards.removeLast();
    participantCards[pos].take(card);
    keeper = pos;
  }

  /// pos的参与者打出一张牌，其他三家检查
  sendCheck(int pos, String card) {
    int nextPos = next(pos);
    ParticipantCard nextParticipant = participantCards[nextPos];
    nextParticipant.sendCheck(card);
    //下家的吃牌检查
    // nextParticipant.drawingCheck(card);

    int opponentPos = opponent(pos);
    ParticipantCard opponentParticipant = participantCards[opponentPos];
    opponentParticipant.sendCheck(card);

    int previousPos = previous(pos);
    ParticipantCard previousParticipant = participantCards[previousPos];
    previousParticipant.sendCheck(card);

    if (nextParticipant.status.isEmpty &&
        opponentParticipant.status.isEmpty &&
        previousParticipant.status.isEmpty) {
      take(nextPos);
    }
  }

  onPass(int pos) {
    ParticipantCard participant = participantCards[pos];
    participant.status.clear();
    int mePos = me;
    int nextPos = next(mePos);
    ParticipantCard nextParticipant = participantCards[nextPos];

    int opponentPos = opponent(mePos);
    ParticipantCard opponentParticipant = participantCards[opponentPos];

    int previousPos = previous(mePos);
    ParticipantCard previousParticipant = participantCards[previousPos];
    if (nextParticipant.status.isEmpty &&
        opponentParticipant.status.isEmpty &&
        previousParticipant.status.isEmpty) {
      take(next(sender!));
    }
  }
}
