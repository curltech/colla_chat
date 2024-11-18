import 'dart:math';
import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// flame引擎渲染的麻将牌
class CardComponent extends RectangleComponent
    with DragCallbacks, TapCallbacks, HasGameRef<MajiangFlameGame> {
  CardComponent(this.card, this.direction, this.cardBackgroundType,
      {super.position})
      : super(priority: 4);

  final Card card;

  /// 0:自己，1:下家，2:对家，3:上家
  final int direction;

  final CardBackgroundType cardBackgroundType;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void _drawSprite(
    Canvas canvas,
    Sprite sprite,
    double relativeX,
    double relativeY, {
    double scale = 1,
    bool rotate = false,
  }) {
    if (rotate) {
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(pi);
      canvas.translate(-size.x / 2, -size.y / 2);
    }
    sprite.render(
      canvas,
      position: Vector2(relativeX * size.x, relativeY * size.y),
      anchor: Anchor.center,
      size: sprite.srcSize.scaled(scale),
    );
    if (rotate) {
      canvas.restore();
    }
  }

  /// 根据不同的牌进行不同的渲染
  /// 自己的手牌handcard
  /// 自己的河牌，碰牌或者杠牌touchcard
  /// 对家的手牌opponenthand
  /// 对家的河牌，碰牌或者杠牌touchcard
  /// 下家的手牌sidehand
  /// 下家的河牌sidecard
  /// 上家的手牌sidehand
  /// 上家的河牌sidecard
  @override
  void render(Canvas canvas) {
    Sprite? backgroundSprite = cardBackgroundSprite.sprites[cardBackgroundType];
    switch (cardBackgroundType) {
      case CardBackgroundType.handcard:
        _drawSprite(canvas, backgroundSprite!, 0, 0);
        _drawSprite(canvas, card.sprite, 0, 0);
        break;
      case CardBackgroundType.touchcard:
        if (direction == 0) {
          _drawSprite(canvas, backgroundSprite!, 0, 0);
          _drawSprite(canvas, card.sprite, 0, 0);
        }
        if (direction == 2) {
          _drawSprite(canvas, backgroundSprite!, 0, 0);
          _drawSprite(canvas, card.sprite, 0, 0);
        }
        break;
      case CardBackgroundType.opponenthand:
        _drawSprite(canvas, backgroundSprite!, 0, 0);
        _drawSprite(canvas, card.sprite, 0, 0);
        break;
      case CardBackgroundType.sidehand:
        if (direction == 1) {
          _drawSprite(canvas, backgroundSprite!, 0, 0);
          _drawSprite(canvas, card.sprite, 0, 0);
        }
        if (direction == 3) {
          _drawSprite(canvas, backgroundSprite!, 0, 0);
          _drawSprite(canvas, card.sprite, 0, 0);
        }
        break;
      case CardBackgroundType.sidecard:
        if (direction == 1) {
          _drawSprite(canvas, backgroundSprite!, 0, 0);
          _drawSprite(canvas, card.sprite, 0, 0);
        }
        if (direction == 3) {
          _drawSprite(canvas, backgroundSprite!, 0, 0);
          _drawSprite(canvas, card.sprite, 0, 0);
        }
        break;
      default:
        break;
    }
  }
}
