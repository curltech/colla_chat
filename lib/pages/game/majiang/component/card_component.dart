import 'dart:math';
import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/card.dart' as majiangCard;
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// flame引擎渲染的麻将牌
class CardComponent extends PositionComponent
    with TapCallbacks, HasGameRef<MajiangFlameGame> {
  CardComponent(this.card, this.direction, this.cardBackgroundType,
      {super.position}) {
    if (direction == 0) {
      size = Vector2(card.sprite.image.width.toDouble(),
          card.sprite.image.height.toDouble());
    }
  }

  final majiangCard.Card card;

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
      canvas.translate(sprite.image.width / 2, sprite.image.height / 2);
      canvas.rotate(pi);
      canvas.translate(-sprite.image.width / 2, -sprite.image.height / 2);
    }
    sprite.render(
      canvas,
      position: Vector2(relativeX * size.x, relativeY * size.y),
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

  void _render(Canvas canvas) {
    Sprite? backgroundSprite = cardBackgroundSprite.sprites[cardBackgroundType];
    if (backgroundSprite == null) {
      return;
    }
    switch (cardBackgroundType) {
      case CardBackgroundType.handcard:
        _drawSprite(canvas, backgroundSprite, 0, 0);
        _drawSprite(canvas, card.sprite, 0, 0);
        break;
      case CardBackgroundType.touchcard:
        if (direction == 0) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, card.sprite, 0, 0);
        }
        if (direction == 2) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, card.sprite, 0, 0);
        }
        break;
      case CardBackgroundType.opponenthand:
        _drawSprite(canvas, backgroundSprite, 0, 0);
        // _drawSprite(canvas, card.sprite, 0, 0);
        break;
      case CardBackgroundType.sidehand:
        if (direction == 1) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          // _drawSprite(canvas, card.sprite, 0, 0);
        }
        if (direction == 3) {
          _drawSprite(canvas, backgroundSprite, 0, 0, rotate: true);
          // _drawSprite(canvas, card.sprite, 0, 0);
        }
        break;
      case CardBackgroundType.sidecard:
        if (direction == 1) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, card.sprite, 0, 0);
        }
        if (direction == 3) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, card.sprite, 0, 0);
        }
        break;
      default:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    _render(canvas);
  }

  send() {
    Room? room = roomController.room.value;
    if (room != null) {
      Round? currentRound = room.currentRound;
      if (currentRound == null) {
        return;
      }
      HandPile handPile = currentRound.roundParticipants[direction].handPile;
      if (handPile.takeCard == card) {
        room.onRoomEvent(RoomEvent(
          room.name,
          currentRound.id,
          direction,
          RoomEventAction.send,
          card: card,
          pos: -1,
        ));
      } else {
        int pos = handPile.cards.indexOf(card);
        if (pos > -1) {
          room.onRoomEvent(RoomEvent(
            room.name,
            currentRound.id,
            direction,
            RoomEventAction.send,
            card: card,
            pos: pos,
          ));
        }
      }
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    /// 点击自家的牌表示打牌
    if (direction == 0) {
      send();
    }
  }
}
