import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum CardBackgroundType {
  background, //桌面
  barcard, //暗杠
  handcard, //自己手牌
  opponentbar, //对家暗杠
  opponenthand, //对家手牌
  poolcard, //自己河牌
  sidebar, //边家暗杠
  sidecard, // 边家出牌
  sidehand, // 边家手牌
  touchcard // 自己碰牌
}

class CardBackgroundSprite {
  static const String majiangPath = 'majiang/';

  final Map<CardBackgroundType, Sprite> sprites = {};

  CardBackgroundSprite() {
    init();
  }

  init() async {
    for (var cardBackgroundType in CardBackgroundType.values) {
      Image image = await Flame.images
          .load('$majiangPath${cardBackgroundType.name}.webp');
      Sprite sprite = Sprite(image);
      sprites[cardBackgroundType] = sprite;
    }
  }
}

final CardBackgroundSprite cardBackgroundSprite = CardBackgroundSprite();
