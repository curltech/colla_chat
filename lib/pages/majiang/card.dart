import 'dart:math';

import 'package:align_positioned/align_positioned.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CardImage {
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
  late final List<String> allCards;

  final windImages = <String, Widget>{};
  final suoImages = <String, Widget>{};
  final tongImages = <String, Widget>{};
  final wanImages = <String, Widget>{};

  CardImage() {
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

final CardImage cardImage = CardImage();

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
              child: cardImage.get(name)!,
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
              child: cardImage.get(name)!,
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
              child: RotatedBox(quarterTurns: 1, child: cardImage.get(name)!),
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
              child: RotatedBox(quarterTurns: 1, child: cardImage.get(name)!),
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
              child: RotatedBox(quarterTurns: -1, child: cardImage.get(name)!),
            ),
          ],
        ));
  }
}

enum ParticipantStatus { touch, bar, darkbar, drawing, complete }

class ParticipantCard {
  final String peerId;

  ///是否是机器人
  final bool robot;

  //手牌
  final RxList<String> handCards = <String>[].obs;

  //碰，杠牌
  final RxList<String> touchCards = <String>[].obs;

  //吃牌
  final RxList<String> drawingCards = <String>[].obs;

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
  sort() {
    handCards.sort((String a, String b) {
      return a.compareTo(b);
    });
  }

  int _checkCount(List<String> cards, String card) {
    int count = 0;
    for (var c in cards) {
      if (c == card) {
        count++;
      }
    }

    return count;
  }

  /// 检查明杠
  bool checkBar(String card) {
    int count = _checkCount(touchCards, card);
    if (count == 3) {
      return true;
    }

    return false;
  }

  /// 检查暗杠
  bool checkDarkBar(String card) {
    int count = _checkCount(handCards, card);
    if (count == 4) {
      return true;
    }

    return false;
  }

  /// 检查碰牌
  bool checkTouch(String card) {
    int count = _checkCount(handCards, card);
    if (count == 2) {
      return true;
    }

    return false;
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
  bool checkComplete(String card) {
    if (handCards.length == 1 && handCards[0] == card) {
      return true;
    }
    if (handCards.length == 4) {
      if (handCards[0] == card) {
        return true;
      }
    }

    return false;
  }

  /// 检查是否可以杠牌，吃牌，碰牌和胡牌
  check(String card) {
    List<ParticipantStatus> participantStatus = [];
    if (checkBar(card)) {
      participantStatus.add(ParticipantStatus.drawing);
    }
    if (checkBar(card)) {
      participantStatus.add(ParticipantStatus.bar);
    }
    if (checkBar(card)) {
      participantStatus.add(ParticipantStatus.darkbar);
    }
    if (checkBar(card)) {
      participantStatus.add(ParticipantStatus.touch);
    }
    if (checkBar(card)) {
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
    touchCards.add(card);
    touchCards.add(card);
    touchCards.add(card);
  }

  /// 明杠牌
  bar(String card) {
    handCards.remove(card);
    handCards.remove(card);
    handCards.remove(card);
    touchCards.add(card);
    touchCards.add(card);
    touchCards.add(card);
    touchCards.add(card);
  }

  /// 暗杠牌
  darkBar(String card) {
    handCards.remove(card);
    handCards.remove(card);
    handCards.remove(card);
    handCards.remove(card);
    touchCards.add(card);
    touchCards.add(card);
    touchCards.add(card);
    touchCards.add(card);
  }

  /// 过牌
  pass() {
    status.clear();
  }

  /// 摸牌，peerId为空，自己摸牌，不为空，别人摸牌
  take(String card) {
    comingCard.value = card;
    check(card);
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

  /// 当前的持有发牌的参与者，正在思考
  int? keeper;

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
    List<String> allCards = [...cardImage.allCards];
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
    participantCards[pos].sort();

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

  /// 摸牌，peerId为空，自己摸牌，不为空，别人摸牌
  take({int? current}) {
    if (current == null) {
      String card = unknownCards.removeLast();
      int pos = me;
      participantCards[pos].take(card);
      keeper = pos;
    } else {
      String card = unknownCards.removeLast();
      participantCards[current].take(card);
      keeper = current;
    }
  }

  /// pos的参与者打出一张牌，其他三家检查
  check(int current, String card) {
    int pos = next(current);
    ParticipantCard participant = participantCards[pos];
    participant.check(card);

    pos = opponent(current);
    participant = participantCards[pos];
    participant.check(card);

    pos = previous(current);
    participant = participantCards[pos];
    participant.check(card);
  }
}
