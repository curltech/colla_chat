import 'dart:math';

import 'package:flutter/material.dart';

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
  Widget handcard({double width = 50.0}) {
    double ratio = width / 50;
    return SizedBox(
        width: width,
        child: Stack(
          children: [
            SizedBox(child: backgroundImage.get('handcard')!),
            Column(children: [
              SizedBox(
                height: 3.0 * ratio,
              ),
              cardImage.get(name)!,
            ]),
          ],
        ));
  }

  /// 自己的碰牌或者杠牌
  Widget touchcard({double width = 46.0}) {
    double ratio = width / 46;
    return SizedBox(
        width: width,
        child: Stack(
          children: [
            SizedBox(
                height: 75 * ratio, child: backgroundImage.get('touchcard')!),
            Row(children: [
              SizedBox(
                width: 2.0 * ratio,
              ),
              SizedBox(
                height: 54.0 * ratio,
                child: cardImage.get(name)!,
              ),
            ])
          ],
        ));
  }

  /// 上家或者下家的河牌
  Widget sidecard({double width = 49.0}) {
    double ratio = width / 49;
    return SizedBox(
        width: width,
        child: Stack(
          children: [
            SizedBox(
                height: width * ratio, child: backgroundImage.get('sidecard')!),
            Row(children: [
              SizedBox(
                width: 2.0 * ratio,
              ),
              SizedBox(
                height: 33.0 * ratio,
                child:
                    RotatedBox(quarterTurns: 45, child: cardImage.get(name)!),
              ),
            ])
          ],
        ));
  }

  ///自己或者对家的河牌
  Widget poolcard({double width = 49.0}) {
    double ratio = width / 49;
    return SizedBox(
        width: width,
        child: Stack(
          children: [
            SizedBox(
                height: width * ratio, child: backgroundImage.get('poolcard')!),
            Row(children: [
              SizedBox(
                width: 2.0 * ratio,
              ),
              SizedBox(
                height: 33.0 * ratio,
                child:
                    RotatedBox(quarterTurns: 45, child: cardImage.get(name)!),
              ),
            ])
          ],
        ));
  }

  Widget rightSidehand({bool clip = true}) {
    if (clip) {
      return ClipRect(
          child: Align(
              alignment: Alignment.topLeft,
              heightFactor: 0.55,
              child: backgroundImage.get('sidehand')!));
    }
    return backgroundImage.get('sidehand')!;
  }

  Widget leftSidehand({bool clip = true}) {
    if (clip) {
      return ClipRect(
          child: Align(
              alignment: Alignment.topLeft,
              heightFactor: 0.55,
              child: RotatedBox(
                  quarterTurns: 90, child: backgroundImage.get('sidehand')!)));
    }
    return RotatedBox(
        quarterTurns: 90, child: backgroundImage.get('sidehand')!);
  }

  Widget opponenthand({double width = 49.0}) {
    return backgroundImage.get('opponenthand')!;
  }
}

enum CardResult { touch, bar, darkbar, complete }

class ParticipantCard {
  String peerId;

  bool host;

  //手牌
  List<String> handCards = [];

  //碰牌
  List<String> touchCards = [];

  //杠牌
  List<String> barCards = [];

  //吃牌
  List<String> drawingCards = [];

  //打出的牌
  List<String> poolCards = [];

  ParticipantCard(this.peerId, {this.host = false});

  clear() {
    handCards.clear();
    touchCards.clear();
    barCards.clear();
    drawingCards.clear();
    poolCards.clear();
  }

  /// 摸一张新牌
  add(String card) {
    handCards.add(card);
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
    int count = _checkCount(barCards, card);
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
}

class MajiangRoom {
  final List<String> allCards = [
    ...cardImage.windImages.keys,
    ...cardImage.suoImages.keys,
    ...cardImage.tongImages.keys,
    ...cardImage.wanImages.keys,
    ...cardImage.windImages.keys,
    ...cardImage.suoImages.keys,
    ...cardImage.tongImages.keys,
    ...cardImage.wanImages.keys,
    ...cardImage.windImages.keys,
    ...cardImage.suoImages.keys,
    ...cardImage.tongImages.keys,
    ...cardImage.wanImages.keys,
    ...cardImage.windImages.keys,
    ...cardImage.suoImages.keys,
    ...cardImage.tongImages.keys,
    ...cardImage.wanImages.keys,
  ];

  //四个参与者的牌
  List<ParticipantCard> participantCards = [
    ParticipantCard('自己', host: true),
    ParticipantCard('下家'),
    ParticipantCard('对家'),
    ParticipantCard('上家')
  ];

  //未知的牌
  List<String> unknownCards = [];

  /// 加参与者，第一个是自己，第二个是下家，第三个是对家，第四个是上家
  addParticipant(ParticipantCard participant) {
    participantCards.add(participant);
  }

  /// 新玩一局
  List<int> play({List<int>? positions}) {
    for (var participantCard in participantCards) {
      participantCard.clear();
    }
    unknownCards.clear();
    List<String> allCards = [...this.allCards];
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
        participantCards[reminder].add(card);
      } else {
        unknownCards.add(card);
      }
    }

    return positions;
  }
}
