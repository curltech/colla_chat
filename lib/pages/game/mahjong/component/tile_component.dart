import 'dart:math';
import 'dart:ui';

import 'package:colla_chat/pages/game/mahjong/base/hand_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_event.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart' as mahjongCard;
import 'package:colla_chat/pages/game/mahjong/base/tile_background_sprite.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// flame引擎渲染的麻将牌
class TileComponent extends PositionComponent
    with TapCallbacks, HasGameRef<MahjongFlameGame> {
  TileComponent(this.tile, this.areaDirection, this.tileBackgroundType,
      {this.tileScale = 1, super.position, super.priority}) {
    if (areaDirection == AreaDirection.self) {
      double width = 79;
      double height = 111;
      if (tile.sprite != null) {
        width = tile.sprite!.image.width.toDouble();
        height = tile.sprite!.image.height.toDouble();
      } else {
        logger.e('tile:$tile sprite image is null');
      }
      size = Vector2(width, height);
    }
  }

  final mahjongCard.Tile tile;

  final AreaDirection areaDirection;

  final TileBackgroundType tileBackgroundType;

  final double tileScale;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void _drawSprite(
    Canvas canvas,
    Sprite? sprite,
    double x,
    double y, {
    double scale = 1,
    double? radians,
  }) {
    if (sprite == null) {
      return;
    }
    scale = scale * tileScale;
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
    Sprite? backgroundSprite = cardBackgroundSprite.sprites[tileBackgroundType];
    if (backgroundSprite == null) {
      return;
    }
    switch (tileBackgroundType) {
      case TileBackgroundType.handcard:
        _drawSprite(canvas, backgroundSprite, 0, 0);
        _drawSprite(canvas, tile.sprite, 3, 10, scale: 0.9);
        break;
      case TileBackgroundType.touchcard:
        if (areaDirection == AreaDirection.self) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, tile.sprite, 0, -10, scale: 0.55);
        }
        if (areaDirection == AreaDirection.opponent) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, tile.sprite, 36, 50, scale: 0.55, radians: pi);
        }
        break;
      case TileBackgroundType.opponenthand:
        _drawSprite(canvas, backgroundSprite, 0, 0);
        // _drawSprite(canvas, card.sprite, 0, 0);
        break;
      case TileBackgroundType.opponentbar:
        _drawSprite(canvas, backgroundSprite, 0, 0);
        // _drawSprite(canvas, card.sprite, 0, 0);
        break;
      case TileBackgroundType.sidehand:
        if (areaDirection == AreaDirection.next) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          // _drawSprite(canvas, card.sprite, 0, 0);
        }
        if (areaDirection == AreaDirection.previous) {
          _drawSprite(canvas, backgroundSprite, 0, 0, radians: pi);
          // _drawSprite(canvas, card.sprite, 0, 0);
        }
        break;
      case TileBackgroundType.sidecard:
        if (areaDirection == AreaDirection.next) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, tile.sprite, 60, 8, scale: 0.5, radians: -pi / 2);
        }
        if (areaDirection == AreaDirection.previous) {
          _drawSprite(canvas, backgroundSprite, 0, 0);
          _drawSprite(canvas, tile.sprite, -21, 40,
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

  discard() {
    RoundParticipant? roundParticipant = roomController
        .getRoundParticipant(roomController.selfParticipantDirection.value);
    Map<RoomEventAction, Set<int>>? outstandingActions =
        roundParticipant?.outstandingActions.value;
    if (outstandingActions != null && outstandingActions.isNotEmpty) {
      return;
    }
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
      if (!roundParticipant.canDiscard()) {
        logger.e(
            'roundParticipant:${roundParticipant.index} cannot discard tile,${roundParticipant.handCount}');
        return;
      }

      HandPile handPile = roundParticipant.handPile;
      if (!handPile.exist(tile)) {
        logger.e(
            'roundParticipant:${roundParticipant.index} cannot discard tile, not exist');
        return;
      }
      if (handPile.drawTile == tile) {
        room.startRoomEvent(RoomEvent(
          room.name,
          roundId: currentRound.id,
          owner: participantDirection.index,
          action: RoomEventAction.discard,
          tile: tile,
          pos: -1,
        ));
      } else {
        int pos = handPile.tiles.indexOf(tile);
        if (pos > -1) {
          room.startRoomEvent(RoomEvent(
            room.name,
            roundId: currentRound.id,
            owner: participantDirection.index,
            action: RoomEventAction.discard,
            tile: tile,
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
      discard();
    }
  }
}
