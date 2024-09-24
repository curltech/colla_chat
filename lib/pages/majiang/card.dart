import 'package:flutter/material.dart';

class CardImage {
  static const List<String> windImageFiles = [
    'assets/images/majiang/card/east.png',
    'assets/images/majiang/card/south.png',
    'assets/images/majiang/card/west.png',
    'assets/images/majiang/card/north.png',
    'assets/images/majiang/card/center.png',
    'assets/images/majiang/card/fortune.png',
    'assets/images/majiang/card/whiteboard.png',
  ];
  static const String suoImageFile = 'assets/images/majiang/card/suo';
  static const String tongImageFile = 'assets/images/majiang/card/tong';
  static const String wanImageFile = 'assets/images/majiang/card/wan';
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
        windImageFiles[i],
        fit: BoxFit.none,
      );
      int start = windImageFiles[i].lastIndexOf('/');
      int end = windImageFiles[i].lastIndexOf('.');
      String name = windImageFiles[i].substring(start, end);
      windImages[name] = image;
    }
    for (int i = 1; i < 10; ++i) {
      var image = Image.asset(
        '$suoImageFile$i.png',
        fit: BoxFit.none,
      );
      suoImages['$suoImageFile$i'] = image;
    }
    for (int i = 1; i < 10; ++i) {
      var image = Image.asset(
        '$tongImageFile$i.png',
        fit: BoxFit.none,
      );
      tongImages['$tongImageFile$i'] = image;
    }
    for (int i = 1; i < 10; ++i) {
      var image = Image.asset(
        '$wanImageFile$i.png',
        fit: BoxFit.none,
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

  BackGroundImage() {
    _load();
  }

  _load() {
    for (int i = 0; i < backgroundImageFiles.length; ++i) {
      var image = Image.asset(
        'assets/images/majiang/${backgroundImageFiles[i]}.webp',
        fit: BoxFit.none,
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

class Card {
  String name;

  Card(this.name);

  Widget? handcar() {
    return Stack(
      children: [
        backgroundImage.get('handcar')!,
        cardImage.get(name)!,
      ],
    );
  }
}
