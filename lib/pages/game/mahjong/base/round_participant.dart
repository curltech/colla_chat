import 'dart:async';

import 'package:colla_chat/pages/game/mahjong/base/tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/hand_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/outstanding_action.dart';
import 'package:colla_chat/pages/game/mahjong/base/participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/pages/game/mahjong/base/waste_pile.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:get/get.dart';

/// 每一轮的参与者
class RoundParticipant {
  /// ParticipantDirection.index
  int index;

  final Participant participant;

  final Round round;

  //积分
  final RxInt score = 0.obs;

  // 手牌，每个参与者只能看到自己的手牌
  final HandPile handPile = HandPile();

  // 打出的牌，每个参与者能看到所有的打出的牌
  final WastePile wastePile = WastePile();

  /// 参与者等待处理的行为
  final RxMap<OutstandingAction, Set<int>> outstandingActions =
      RxMap<OutstandingAction, Set<int>>({});

  /// 参与者已经发生的行为，比如，明杠，暗杠等，值数组代表行为的发生人
  /// 自己代表自摸杠，别人代表打牌杠
  final Map<OutstandingAction, Set<int>> earnedActions =
      <OutstandingAction, Set<int>>{};

  /// 记录重要的事件
  final List<RoomEvent> roomEvents = [];

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  /// 包了自己的胡牌的人
  int? packer;

  RoundParticipant(this.index, this.round, this.participant);

  ParticipantDirection get direction {
    return NumberUtil.toEnum(ParticipantDirection.values, index)!;
  }

  clear() {
    outstandingActions.clear();
    earnedActions.clear();
    packer = null;
  }

  int get total {
    return handPile.total + wastePile.tiles.length;
  }

  int get handCount {
    return handPile.count;
  }

  bool get canDiscard {
    return handCount == 14;
  }

  addOutstandingAction(OutstandingAction outstandingAction, List<int> vs) {
    Set<int>? values = outstandingActions[outstandingAction];
    if (values == null) {
      values = {};
      outstandingActions[outstandingAction] = values;
    }
    values.addAll(vs);
  }

  addEarnedAction(OutstandingAction outstandingAction, List<int> vs) {
    Set<int>? values = earnedActions[outstandingAction];
    if (values == null) {
      values = {};
      earnedActions[outstandingAction] = values;
    }
    values.addAll(vs);
  }

  /// 摸牌，有三种摸牌，普通的自摸，海底捞的自摸，杠上自摸
  /// owner摸到card牌，takeCardType表示摸牌的方式
  Map<OutstandingAction, Set<int>>? deal(
      int owner, Tile tile, int dealTileTypeIndex) {
    if (owner != index) {
      return null;
    }
    DealTileType? dealTileType =
        NumberUtil.toEnum(DealTileType.values, dealTileTypeIndex);
    if (dealTileType == null) {
      return null;
    }
    if (handPile.drawTile != null) {
      logger.e('draw tile is not null');
    }
    handPile.drawTile = tile;
    handPile.drawTileType = dealTileType;

    /// 检查摸到的牌，看需要采取的动作，这里其实只需要摸牌检查
    Map<OutstandingAction, Set<int>> outstandingActions =
        check(tile: tile, dealTileType: dealTileType);
    if (outstandingActions.isNotEmpty) {
      roomController.mahjongFlameGame.loadActionArea();
    }

    return outstandingActions;
  }

  /// 打牌，owner打出牌card，对其他人检查打的牌是否能够胡牌，杠牌和碰牌，返回检查的结果
  bool discard(int owner, Tile card) {
    if (owner != index) {
      return false;
    }
    if (!canDiscard) {
      return false;
    }
    wastePile.tiles.add(card);

    return handPile.discard(card);
  }

  /// 检查行为状态，既包括摸牌检查，也包含打牌检查
  Map<OutstandingAction, Set<int>> check(
      {Tile? tile, DealTileType? dealTileType}) {
    logger.w('$index check tile ${tile.toString()}');
    outstandingActions.clear();
    if (dealTileType == DealTileType.sea) {
      WinType? winType = handPile.checkWin(tile: tile);
      if (winType != null) {
        addOutstandingAction(OutstandingAction.win, [winType.index]);
      } else {
        addOutstandingAction(OutstandingAction.pass, []);
      }
      return outstandingActions.value;
    }
    WinType? winType = handPile.checkWin(tile: tile);
    if (winType != null) {
      addOutstandingAction(OutstandingAction.win, [winType.index]);
    }
    if (tile == handPile.drawTile) {
      List<int>? pos = handPile.checkDarkBar();
      if (pos != null) {
        addOutstandingAction(OutstandingAction.darkBar, pos);
      }
      pos = handPile.checkDrawBar();
      if (pos != null) {
        addOutstandingAction(OutstandingAction.bar, pos);
      }
    } else if (tile != null) {
      int? pos = handPile.checkDiscardBar(tile);
      if (pos != null) {
        addOutstandingAction(OutstandingAction.bar, [pos]);
      }
      pos = handPile.checkTouch(tile);
      if (pos != null) {
        addOutstandingAction(OutstandingAction.touch, [pos]);
      }
    }

    if (outstandingActions.value.isNotEmpty) {
      roomController.mahjongFlameGame.loadActionArea();
    }

    return outstandingActions.value;
  }

  /// 过牌，owner宣布不做任何操作
  pass(int owner) {
    if (index != owner) {
      return;
    }
    outstandingActions.clear();
    if (handPile.drawTileType == DealTileType.sea) {
      round.room.onRoomEvent(RoomEvent(round.room.name,
          roundId: round.id,
          owner: round.room.next(owner),
          action: RoomEventAction.deal));
    }
  }

  /// 碰牌,owner碰pos位置，sender打出的card牌
  bool touch(int owner, int pos, int sender, Tile tile) {
    if (index == owner) {
      return handPile.touch(pos, tile);
    }

    return true;
  }

  /// 杠牌，分成打牌杠牌_discardBar和摸牌杠牌_drawBar
  Tile? bar(int owner, int pos, {Tile? tile, int? discard}) {
    if (index == owner) {
      if (discard != null) {
        return discardBar(owner, pos, tile!, discard);
      } else {
        return drawBar(owner, pos);
      }
    }

    return null;
  }

  /// 打牌杠牌，分成打牌杠牌sendBar和摸牌杠牌takeBar
  Tile? discardBar(int owner, int pos, Tile tile, int discard) {
    if (index == owner) {
      Tile? c = handPile.discardBar(pos, tile, discard);
      if (c != null) {
        addEarnedAction(OutstandingAction.bar, [pos]);
      }

      return c;
    }

    return null;
  }

  /// owner明杠位置pos的牌，分两种情况，摸牌杠牌和打牌杠牌
  /// 打牌杠牌的时候sender不为空，表示打牌的参与者
  /// pos表示杠牌的位置,如果摸牌杠牌的时候为手牌杠牌的位置，打牌杠牌的时候是杠牌的位置
  /// 返回值为杠的牌，为空表示未成功
  Tile? drawBar(int owner, int pos) {
    if (index == owner) {
      Tile? card = handPile.drawBar(pos, owner);
      if (card != null) {
        addEarnedAction(OutstandingAction.bar, [pos]);
      }

      return card;
    }

    return null;
  }

  /// 暗杠牌，owner杠手上pos位置已有的四张牌（card==null）或者新进的card（card!=null）
  Tile? darkBar(int owner, int pos) {
    if (index == owner) {
      Tile? card = handPile.darkBar(pos, owner);
      if (card != null) {
        addEarnedAction(OutstandingAction.bar, [pos]);
      }

      return card;
    }

    return null;
  }

  /// 吃牌，owner在pos位置吃上家的牌card
  Tile? chow(int owner, int pos, Tile tile) {
    if (index == owner) {
      Tile? c = handPile.chow(pos, tile);

      return c;
    }

    return null;
  }

  WinType? checkWin(int owner, Tile tile) {
    if (index == owner) {
      return handPile.checkWin(tile: tile);
    }

    return null;
  }

  /// 胡牌，owner胡participantState中的可胡的牌形,pos表示可胡牌形数组的位置
  WinType? win(int owner, int win) {
    if (index == owner) {
      Set<int>? wins = outstandingActions[OutstandingAction.win];
      if (wins != null && wins.isNotEmpty) {
        WinType? winType = NumberUtil.toEnum(WinType.values, win);
        if (winType != null) {
          logger.i('win:$winType');
        }

        return winType;
      }
    }

    return null;
  }

  /// 抢杠胡牌，owner抢src的明杠牌card胡牌
  WinType? rob(int owner, int pos, Tile tile, int src) {
    if (index == owner) {
      Set<int>? wins = outstandingActions[OutstandingAction.win];
      if (wins != null && wins.isNotEmpty) {
        if (wins.contains(pos)) {
          WinType? winType = NumberUtil.toEnum(WinType.values, pos);
          if (winType != null) {
            logger.i('win:$winType');
          }

          return winType;
        }
      }
    }

    return null;
  }
}
