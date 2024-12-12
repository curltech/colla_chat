import 'dart:math';
import 'dart:ui';

import 'package:colla_chat/pages/game/majiang/base/card.dart' as majiangCard;
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/base/round_participant.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// flame引擎渲染的麻将牌
class CardComponent extends PositionComponent
    with TapCallbacks, HasGameRef<MajiangFlameGame> {
  CardComponent(this.card, this.areaDirection, this.cardBackgroundType,
      {super.position, super.priority}) {
    if (areaDirection == AreaDirection.self) {
      size = Vector2(card.sprite.image.width.toDouble(),
          card.sprite.image.height.toDouble());
    }
  }

  final majiangCard.Card card;

  final AreaDirection areaDirection;

  final CardBackgroundType cardBackgroundType;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void _drawSprite(
    Canvas canvas,
    Sprite sprite,
    double x,
    double y, {
    double scale = 1,
    double? radians,
  }) {
    if (radians != null) {
      canvas.save();
      canvas.translate(sprite.image.width / 2, sprite.image.height / 2);
      canvas.rotate(radians);
      canvas.translate(-sprite.image.width / 2, -sprite.image.height / 2);
    }
    sprite.render(
      canvas,
      position: Vector2(x, y),
      size: sprite.srcSize.scaled(scale),
    );
    if (radians != null) {
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
        _drawSprite(canvas, card.sprite, 3, 10, scale: 0.9);
        break;
      case CardBackgroundType.touchcard:
        if (areaDirection == AreaDirection.self) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, card.sprite, 0, -10, scale: 0.55);
        }
        if (areaDirection == AreaDirection.opponent) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, card.sprite, 36, 50, scale: 0.55, radians: pi);
        }
        break;
      case CardBackgroundType.opponenthand:
        _drawSprite(canvas, backgroundSprite, 0, 0);
        // _drawSprite(canvas, card.sprite, 0, 0);
        break;
      case CardBackgroundType.opponentbar:
        _drawSprite(canvas, backgroundSprite, 0, 0);
        // _drawSprite(canvas, card.sprite, 0, 0);
        break;
      case CardBackgroundType.sidehand:
        if (areaDirection == AreaDirection.next) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          // _drawSprite(canvas, card.sprite, 0, 0);
        }
        if (areaDirection == AreaDirection.previous) {
          _drawSprite(canvas, backgroundSprite, 0, 0, radians: pi);
          // _drawSprite(canvas, card.sprite, 0, 0);
        }
        break;
      case CardBackgroundType.sidecard:
        if (areaDirection == AreaDirection.next) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, card.sprite, 60, 8, scale: 0.5, radians: -pi / 2);
        }
        if (areaDirection == AreaDirection.previous) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, card.sprite, -21, 40,
              scale: 0.5, radians: pi / 2);
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
      ParticipantDirection participantDirection =
          roomController.getParticipantDirection(areaDirection);
      RoundParticipant roundParticipant =
          currentRound.roundParticipants[participantDirection.index];
      if (!roundParticipant.canSend) {
        logger.e(
            'roundParticipant:${roundParticipant.index} cannot send card,${roundParticipant.handCount}');
        return;
      }
      HandPile handPile =
          currentRound.roundParticipants[participantDirection.index].handPile;
      if (handPile.takeCard == card) {
        room.onRoomEvent(RoomEvent(
          room.name,
          currentRound.id,
          participantDirection.index,
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
            participantDirection.index,
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
    if (areaDirection == AreaDirection.self) {
      send();
    }
  }
}
