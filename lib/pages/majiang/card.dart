import 'dart:math';

import 'package:align_positioned/align_positioned.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CardImage {
  static const String majiangCardPath = 'assets/images/majiang/card/';
  static const List<String> windImageFiles = [
    'east',
    'south',
    'west',
    'north',
    'center',
    'fortune',
    'whiteboard',
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
        width: 50.0 * ratio,
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
        height: 66 * ratio,
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
        width: 49.0 * ratio, child: backgroundImage.get('opponenthand')!);
  }

  /// 对家的河牌，碰牌或者杠牌
  Widget opponentTouchCard({double ratio = 1.0}) {
    return SizedBox(
        width: 44 * ratio,
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
  Widget rightSideHand({double ratio = 1.0, bool clip = true}) {
    Widget clipWidget = backgroundImage.get('sidehand')!;
    if (clip) {
      clipWidget = ClipRect(
          child: Align(
              alignment: Alignment.topLeft,
              heightFactor: 0.55,
              child: clipWidget));
    }

    return SizedBox(width: 22 * ratio, child: clipWidget);
  }

  /// 下家的河牌
  Widget rightSideTouchCard({double ratio = 1.0}) {
    return SizedBox(
        width: 47.0 * ratio,
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
  Widget leftSideHand({double ratio = 1.0, bool clip = true}) {
    Widget clipWidget =
        RotatedBox(quarterTurns: 2, child: backgroundImage.get('sidehand')!);
    if (clip) {
      clipWidget = ClipRect(
          child: Align(
              alignment: Alignment.topLeft,
              heightFactor: 0.55,
              child: clipWidget));
    }
    return SizedBox(width: 22 * ratio, child: clipWidget);
  }

  /// 上家的河牌
  Widget leftSideTouchCard({double ratio = 1.0}) {
    return SizedBox(
        width: 47.0 * ratio,
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

enum CardResult { touch, bar, darkbar, complete }

class ParticipantCard {
  final String peerId;

  //是否庄家
  RxBool host = false.obs;

  //手牌
  final RxList<String> handCards = <String>[].obs;

  //碰，杠牌
  final RxList<String> touchCards = <String>[].obs;

  //吃牌
  final RxList<String> drawingCards = <String>[].obs;

  //打出的牌
  final RxList<String> poolCards = <String>[].obs;

  final Rx<String?> comingCard = Rx<String?>(null);

  ParticipantCard(this.peerId);

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
  check(String card) {}

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
}

/// 麻将房间
class MajiangRoom {
  final String name;

  //四个参与者的牌
  final List<ParticipantCard> participantCards = [];

  //未知的牌
  List<String> unknownCards = [];

  //当前的参与者，正在思考
  ParticipantCard? tokenParticipantCard;

  MajiangRoom(this.name, List<String> peerIds) {
    _init(peerIds);
  }

  /// 加参与者，第一个是自己，第二个是下家，第三个是对家，第四个是上家
  _init(List<String> peerIds) {
    for (var peerId in peerIds) {
      participantCards.add(ParticipantCard(peerId));
    }
    participantCards[0].host.value = true;
  }

  /// 新玩一局，positions为空自己发牌，不为空，别人发牌
  List<int> play({String? peerId, List<int>? positions}) {
    for (var participantCard in participantCards) {
      participantCard.clear();
    }
    unknownCards.clear();
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
    participantCards[0].sort();
    if (peerId == null) {
      tokenParticipantCard = participantCards[0];
    } else {
      ParticipantCard? participantCard = get(peerId);
      if (participantCard != null) {
        tokenParticipantCard = participantCard;
      }
    }

    return positions;
  }

  ParticipantCard? get(String peerId) {
    for (var participantCard in participantCards) {
      if (participantCard.peerId == peerId) {
        return participantCard;
      }
    }
    return null;
  }

  /// 摸牌，peerId为空，自己摸牌，不为空，别人摸牌
  take({String? peerId}) {
    if (peerId == null) {
      String card = unknownCards.removeLast();
      participantCards[0].comingCard.value = card;
      tokenParticipantCard = participantCards[0];
    } else {
      ParticipantCard? participantCard = get(peerId);
      if (participantCard != null) {
        String card = unknownCards.removeLast();
        participantCard.comingCard.value = card;
        tokenParticipantCard = participantCard;
      }
    }
  }
}
