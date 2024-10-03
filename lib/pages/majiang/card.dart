import 'package:align_positioned/align_positioned.dart';
import 'package:flutter/material.dart';

class CardConcept {
  static const String majiangCardPath = 'assets/images/majiang/card/';
  static const String majiangPath = 'assets/images/majiang/';
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
  static const List<String> actions = [
    'bar',
    'complete',
    'drawing',
    'pass',
    'selfcomplete',
    'touch',
  ];

  late final List<String> allCards;

  final windImages = <String, Widget>{};
  final suoImages = <String, Widget>{};
  final tongImages = <String, Widget>{};
  final wanImages = <String, Widget>{};
  final stateImages = <String, Widget>{};

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
    for (int i = 0; i < actions.length; ++i) {
      var image = Image.asset(
        '$majiangPath${actions[i]}.webp',
        fit: BoxFit.cover,
      );

      stateImages[actions[i]] = image;
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

  Widget? getCardImage(String name) {
    Widget? image = windImages[name];
    image ??= suoImages[name];
    image ??= tongImages[name];
    image ??= wanImages[name];

    return image;
  }

  Widget? getStateImage(String name) {
    Widget? image = stateImages[name];

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
              child: cardConcept.getCardImage(name)!,
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
              dy: -11.0 * ratio,
              touch: Touch.inside,
              child: cardConcept.getCardImage(name)!,
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
              dx: 0.0 * ratio,
              dy: 0.0 * ratio,
              touch: Touch.inside,
              child: RotatedBox(
                  quarterTurns: 2, child: cardConcept.getCardImage(name)!),
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
              heightFactor: 0.45,
              child: clipWidget));
    }

    return SizedBox(width: 22.0 * ratio, child: clipWidget);
  }

  /// 下家的河牌
  Widget nextTouchCard({double ratio = 1.0, bool clip = true}) {
    Widget clipWidget = backgroundImage.get('sidecard')!;
    if (clip) {
      BoxDecoration decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [BoxShadow(offset: Offset(0.0, 1.0))],
        shape: BoxShape.rectangle,
        color: Colors.white,
      );
      clipWidget = Container(
        decoration: decoration,
        width: 47.0 * ratio,
        height: 43.0 * 0.73 * ratio,
      );
      // clipWidget = ClipRect(
      //     child: Align(
      //         alignment: Alignment.topLeft,
      //         heightFactor: .73,
      //         child: clipWidget));
    }

    Widget imageWidget = SizedBox(
        width: 47.0 * ratio,
        height: 43.0 * 0.73 * ratio,
        child: RotatedBox(
            quarterTurns: -1, child: cardConcept.getCardImage(name)!));

    Widget cardWidget = SizedBox(
        width: 47.0 * ratio,
        height: clip ? 43.0 * 0.73 * ratio : 43.0 * ratio,
        child: Stack(
          children: [
            clipWidget,
            AlignPositioned(
              alignment: Alignment.topLeft,
              dx: -3.0 * ratio,
              dy: 0.0 * ratio,
              touch: Touch.inside,
              child: imageWidget,
            ),
          ],
        ));

    return cardWidget;
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
  Widget previousTouchCard({double ratio = 1.0, bool clip = true}) {
    Widget clipWidget = backgroundImage.get('sidecard')!;
    if (clip) {
      BoxDecoration decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [BoxShadow(offset: Offset(0.0, 1.0))],
        shape: BoxShape.rectangle,
        color: Colors.white,
      );
      clipWidget = Container(
        decoration: decoration,
        width: 47.0 * ratio,
        height: 43.0 * 0.73 * ratio,
      );
    }

    Widget imageWidget = SizedBox(
        width: 47.0 * ratio,
        height: 43.0 * 0.73 * ratio,
        child: RotatedBox(
            quarterTurns: 1, child: cardConcept.getCardImage(name)!));

    Widget cardWidget = SizedBox(
        width: 47.0 * ratio,
        height: clip ? 43.0 * 0.73 * ratio : 43.0 * ratio,
        child: Stack(
          children: [
            clipWidget,
            AlignPositioned(
              alignment: Alignment.topLeft,
              dx: 3.0 * ratio,
              dy: 0.0 * ratio,
              touch: Touch.inside,
              child: imageWidget,
            ),
          ],
        ));

    return cardWidget;
  }
}
