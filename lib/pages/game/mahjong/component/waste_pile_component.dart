import 'dart:async';

import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart' as mahjongTile;
import 'package:colla_chat/pages/game/mahjong/base/tile_background_sprite.dart';
import 'package:colla_chat/pages/game/mahjong/base/waste_pile.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/component/tile_component.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// flame引擎渲染的麻将牌
class WastePileComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameRef<MahjongFlameGame> {
  WastePileComponent(this.areaDirection, {super.scale}) {
    if (areaDirection == AreaDirection.self) {
      position = Vector2(10, 130);
    } else if (areaDirection == AreaDirection.opponent) {
      position = Vector2(10, 10);
    } else if (areaDirection == AreaDirection.next) {
      position = Vector2(126, 10);
    } else if (areaDirection == AreaDirection.previous) {
      position = Vector2(10, 10);
    }
  }

  final AreaDirection areaDirection;

  WastePile? get wastePile {
    return roomController.getWastePile(areaDirection);
  }

  /// 是否刚打出的牌
  bool last() {
    if (wastePile == null) {
      return false;
    }
    bool last = false;
    mahjongTile.Tile? lastCard = wastePile!.tiles.lastOrNull;
    if (lastCard != null) {
      RoundParticipant? roundParticipant =
          roomController.findRoundParticipant(areaDirection);
      if (roundParticipant != null) {
        int? sender = roundParticipant.round.discardToken?.discardParticipant;
        if (sender == roundParticipant.index) {
          mahjongTile.Tile? sendCard = roundParticipant.round.discardToken?.discardTile;
          if (lastCard == sendCard) {
            last = true;
          }
        }
      }
    }

    return last;
  }

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadWastePile() {
    if (wastePile == null) {
      return;
    }
    TileBackgroundType cardBackgroundType;
    if (areaDirection == AreaDirection.self) {
      cardBackgroundType = TileBackgroundType.touchcard;
    } else if (areaDirection == AreaDirection.opponent) {
      cardBackgroundType = TileBackgroundType.touchcard;
    } else {
      cardBackgroundType = TileBackgroundType.sidecard;
    }
    double x = 0;
    double y = 0;
    int priority = 8;
    for (int i = 0; i < wastePile!.tiles.length; ++i) {
      mahjongTile.Tile card = wastePile!.tiles[i];
      int mod = i ~/ 10;
      int reminder = i % 10;
      if (reminder == 0) {
        if (areaDirection == AreaDirection.self) {
          x = 0;
          y = -mod * 55 - 29;
          priority = 8 - mod;
        }
        if (areaDirection == AreaDirection.opponent) {
          x = 0;
          y = mod * 55;
        }
        if (areaDirection == AreaDirection.next) {
          x = -mod * 47 - 24;
          y = 0;
        }
        if (areaDirection == AreaDirection.previous) {
          x = mod * 47;
          y = 0;
        }
      }
      Vector2 position = Vector2(x, y);
      if (areaDirection == AreaDirection.self) {
        x += 44;
      }
      if (areaDirection == AreaDirection.opponent) {
        x += 44;
      }
      if (areaDirection == AreaDirection.next) {
        y += 33;
      }
      if (areaDirection == AreaDirection.previous) {
        y += 33;
      }
      TileComponent cardComponent = TileComponent(
          card, areaDirection, cardBackgroundType,
          position: position, priority: priority);
      add(cardComponent);
    }
  }

  @override
  FutureOr<void> onLoad() {
    loadWastePile();

    return super.onLoad();
  }
}
