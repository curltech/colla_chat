import 'dart:async';

import 'package:colla_chat/pages/game/mahjong/base/format_tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/hand_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_event.dart';
import 'package:colla_chat/pages/game/mahjong/base/mahjong_action_strategy.dart';
import 'package:colla_chat/pages/game/mahjong/base/participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/waste_pile.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
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
  final RxMap<RoomEventAction, Set<int>> outstandingActions =
      RxMap<RoomEventAction, Set<int>>({});

  /// 杠牌的记录，用于计分
  final Map<RoomEventAction, Set<RoomEvent>> earnedActions =
      <RoomEventAction, Set<RoomEvent>>{};

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

  bool canDiscard() {
    return handCount == 14;
  }

  addOutstandingAction(RoomEventAction outstandingAction, List<int> vs) {
    Set<int>? values = outstandingActions[outstandingAction];
    if (values == null) {
      values = {};
      outstandingActions[outstandingAction] = values;
    }
    values.addAll(vs);
  }

  addEarnedAction(RoomEventAction earnedAction, List<RoomEvent> roomEvents) {
    Set<RoomEvent>? values = earnedActions[earnedAction];
    if (values == null) {
      values = {};
      earnedActions[earnedAction] = values;
    }
    values.addAll(roomEvents);
  }

  /// 摸牌，有三种摸牌，普通的自摸，海底捞的自摸，杠上自摸
  /// owner摸到tile牌，dealTileType表示摸牌的方式
  Map<RoomEventAction, Set<int>>? deal(
      int owner, Tile tile, int dealTileTypeIndex) {
    if (owner != index) {
      return null;
    }
    DealTileType? dealTileType =
        NumberUtil.toEnum(DealTileType.values, dealTileTypeIndex);
    if (dealTileType == null) {
      logger.e('participant:$index draw tile dealTileType is null');
      return null;
    }
    if (handPile.drawTile != null) {
      logger.e('participant:$index draw tile is not null');
      return null;
    }

    if (tile != unknownTile && handPile.exist(tile)) {
      logger.e('participant:$index draw tile:$tile is exist');
      return null;
    }

    handPile.drawTile = tile;
    handPile.drawTileType = dealTileType;
    round.discardToken = null;
    // logger.w('owner:$owner deal tile:$tile successfully, discardToken is null');

    /// 检查摸到的牌，看需要采取的动作，这里其实只需要摸牌检查
    if (tile != unknownTile) {
      check(owner, tile, dealTileType: dealTileType);

      robotDiscard();
      mahjongFlameGame.reload();
    }

    return outstandingActions;
  }

  /// 打牌，owner打出牌card，对其他人检查打的牌是否能够胡牌，杠牌和碰牌，返回检查的结果
  /// -1:owner不对，0:数目不对,
  RoomEventActionResult discard(int owner, Tile tile) {
    if (owner != index) {
      return RoomEventActionResult.error;
    }
    if (!canDiscard()) {
      logger.e('participant:$index owner:$owner can not discard:$tile');

      return RoomEventActionResult.count;
    }
    if (!handPile.exist(tile)) {
      logger.e('participant:$index owner:$owner is not exist discard:$tile');

      return RoomEventActionResult.exist;
    }
    if (wastePile.exist(tile)) {
      logger.e('participant:$index owner:$owner wastePile exist discard:$tile');
    } else {
      wastePile.tiles.add(tile);
      logger.i('participant:$index owner:$owner wastePile add discard:$tile');
    }

    RoomEventActionResult result = handPile.discard(tile);

    return result;
  }

  /// 检查行为状态，既包括摸牌检查，也包含打牌检查，还包含机器人自动处理
  Map<RoomEventAction, Set<int>> check(int owner, Tile tile,
      {DealTileType? dealTileType}) {
    outstandingActions.clear();
    if (tile == unknownTile) {
      return outstandingActions;
    }
    round.roomEvents.add(RoomEvent(
      round.room.name,
      roundId: round.id,
      owner: index,
      tile: tile,
      pos: dealTileType?.index,
      src: owner,
      action: RoomEventAction.check,
    ));
    if (dealTileType == DealTileType.sea) {
      WinType? winType = handPile.checkWin(tile: tile);
      if (winType != null) {
        addOutstandingAction(RoomEventAction.win, [winType.index]);
      } else {
        addOutstandingAction(RoomEventAction.pass, []);
      }
      return outstandingActions.value;
    }

    /// 可以胡牌
    WinType? winType = handPile.checkWin(tile: tile);
    if (winType != null) {
      addOutstandingAction(RoomEventAction.win, [winType.index]);
    }

    /// 摸牌检查
    if (tile == handPile.drawTile) {
      /// 摸牌检查暗杠牌
      List<int>? pos = handPile.checkDarkBar();
      if (pos != null) {
        addOutstandingAction(RoomEventAction.darkBar, pos);
      }

      /// 摸牌检查明杠牌
      pos = handPile.checkDrawBar();
      if (pos != null) {
        addOutstandingAction(RoomEventAction.bar, pos);
      }
    } else {
      /// 打牌检查杠牌
      int? pos = handPile.checkDiscardBar(tile);
      if (pos != null) {
        addOutstandingAction(RoomEventAction.bar, [pos]);
      }

      /// 打牌检查碰牌
      pos = handPile.checkTouch(tile);
      if (pos != null) {
        addOutstandingAction(RoomEventAction.touch, [pos]);
      }
    }

    // logger.w(
    //     'participant:$index check tile:$tile, outstandingAction:${outstandingActions.value}');

    robotCheck(owner, tile, dealTileType: dealTileType);

    if (outstandingActions.value.isNotEmpty) {
      mahjongFlameGame.reload();
    }

    return outstandingActions.value;
  }

  WinType? checkWin(int owner, Tile tile) {
    if (index != owner) {
      return null;
    }
    WinType? winType = handPile.checkWin(tile: tile);
    if (winType != null) {
      addOutstandingAction(RoomEventAction.win, [winType.index]);
    }

    return winType;
  }

  /// 当机器参与者有未决的行为时，自动采取行为
  robotCheck(int owner, Tile tile, {DealTileType? dealTileType}) async {
    Room room = round.room;
    RoomEvent robotCheckEvent = RoomEvent(
      round.room.name,
      roundId: round.id,
      owner: index,
      tile: tile,
      pos: dealTileType?.index,
      src: owner,
      action: RoomEventAction.robotCheck,
    );
    round.roomEvents.add(robotCheckEvent);
    Map<RoomEventAction, Set<int>> outstandingActions =
        this.outstandingActions.value;

    RoomEvent passEvent = RoomEvent(
      round.room.name,
      roundId: round.id,
      owner: index,
      tile: tile,
      pos: dealTileType?.index,
      src: owner,
      action: RoomEventAction.pass,
    );

    ///如果没有任何可采取的行为，无论是否机器，都是pass事件
    if (dealTileType == null && outstandingActions.isEmpty) {
      await room.startRoomEvent(passEvent);

      return;
    }

    ///如果不是机器
    if (!participant.robot) {
      return;
    }

    ///如果有可采取的行为
    Set<int>? pos = outstandingActions[RoomEventAction.win];
    if (pos != null) {
      robotCheckEvent.action = RoomEventAction.win;
      robotCheckEvent.pos = pos.first;
      await room.startRoomEvent(robotCheckEvent);
    }
    pos = outstandingActions[RoomEventAction.darkBar];
    if (pos != null) {
      Tile? tile = handPile.drawTile;
      if (tile != null) {
        RoomEventAction mahjongAction = drawBarDecide(tile);
        if (mahjongAction == RoomEventAction.darkBar) {
          robotCheckEvent.action = RoomEventAction.darkBar;
          robotCheckEvent.tile = tile;
          robotCheckEvent.pos = pos.first;
          await room.startRoomEvent(robotCheckEvent);
        } else {
          await room.startRoomEvent(passEvent);
        }
      }
    }
    pos = outstandingActions[RoomEventAction.bar];
    if (pos != null) {
      RoomEventAction? roomEventAction;
      Tile? tile = handPile.drawTile;
      if (tile != null) {
        roomEventAction = drawBarDecide(tile);
      } else {
        tile = round.discardToken?.discardTile;
        if (tile != null) {
          roomEventAction = discardBarDecide(tile);
        }
      }
      if (roomEventAction == RoomEventAction.bar) {
        robotCheckEvent.action = RoomEventAction.bar;
        robotCheckEvent.tile = tile;
        robotCheckEvent.pos = pos.first;
        await room.startRoomEvent(robotCheckEvent);
      } else {
        await room.startRoomEvent(passEvent);
      }
    }

    pos = outstandingActions[RoomEventAction.touch];
    if (pos != null) {
      Tile? tile = round.discardToken?.discardTile;
      if (tile != null) {
        RoomEventAction roomEventAction = discardBarDecide(tile);
        if (roomEventAction == RoomEventAction.touch) {
          robotCheckEvent.action = RoomEventAction.touch;
          robotCheckEvent.tile = round.discardToken?.discardTile;
          robotCheckEvent.src = round.discardToken?.discardParticipant;
          robotCheckEvent.pos = pos.first;
          await room.startRoomEvent(robotCheckEvent);
        } else {
          await room.startRoomEvent(passEvent);
        }
      }
    }

    return;
  }

  /// 过牌，owner宣布不做任何操作
  pass(int owner) {
    if (index != owner) {
      return;
    }
    outstandingActions.clear();
  }

  /// 碰牌,owner碰pos位置，sender打出的card牌
  TypePile? touch(int owner, int pos, int discardParticipant, Tile tile) {
    if (index != owner) {
      return null;
    }
    TypePile? typePile = handPile.touch(pos, tile);
    if (typePile != null && handPile.touchPiles.length == 4) {
      packer = discardParticipant;
    }
    outstandingActions.clear();

    return typePile;
  }

  /// 打牌杠牌discardBar
  TypePile? discardBar(int owner, int pos, Tile tile, int discardParticipant) {
    if (index != owner) {
      return null;
    }
    TypePile? typePile = handPile.discardBar(pos, tile, discardParticipant);
    if (typePile != null) {
      addEarnedAction(RoomEventAction.bar, [
        RoomEvent(round.room.name,
            roundId: round.id,
            action: RoomEventAction.bar,
            owner: owner,
            src: discardParticipant),
      ]);
    }
    if (handPile.touchPiles.length == 4) {
      packer = discardParticipant;
    }

    return typePile;
  }

  /// 摸牌杠牌和手牌杠牌drawBar
  /// owner明杠位置，pos的值分两种情况，摸牌杠牌和手牌杠牌
  /// 摸牌杠牌和手牌杠牌:pos为-1，表示是摸牌可杠，否则表示手牌可杠的位置
  TypePile? drawBar(int owner, int pos, {Tile? tile}) {
    if (index != owner) {
      return null;
    }
    TypePile? typePile = handPile.drawBar(pos, owner, tile: tile);
    if (typePile != null) {
      addEarnedAction(RoomEventAction.bar, [
        RoomEvent(round.room.name,
            roundId: round.id,
            action: RoomEventAction.bar,
            owner: owner,
            src: owner),
      ]);
    }

    return typePile;
  }

  /// 暗杠牌，owner杠手上pos位置已有的四张牌（tile==null）或者新进的tile（tile!=null）
  TypePile? darkBar(int owner, int pos) {
    if (index != owner) {
      return null;
    }
    TypePile? typePile = handPile.darkBar(pos, owner);
    if (typePile != null) {
      addEarnedAction(RoomEventAction.darkBar, [
        RoomEvent(round.room.name,
            roundId: round.id,
            action: RoomEventAction.darkBar,
            owner: owner,
            src: owner),
      ]);
    }

    return typePile;
  }

  /// 吃牌，owner在pos位置吃上家的牌card
  TypePile? chow(int owner, int pos, Tile tile) {
    if (index == owner) {
      TypePile? typePile = handPile.chow(pos, tile);

      return typePile;
    }

    return null;
  }

  /// 胡牌，owner胡participantState中的可胡的牌形,pos表示可胡牌形数组的位置
  WinType? win(int owner, int win) {
    if (index == owner) {
      Set<int>? wins = outstandingActions[RoomEventAction.win];
      if (wins != null && wins.isNotEmpty) {
        WinType? winType = NumberUtil.toEnum(WinType.values, win);
        if (winType != null) {
          logger.i('participant:$index win:$winType');
        }

        return winType;
      }
    }

    return null;
  }

  /// 抢杠胡牌，owner抢src的明杠牌card胡牌
  WinType? rob(int owner, int pos, Tile tile, int src) {
    if (index == owner) {
      Set<int>? wins = outstandingActions[RoomEventAction.win];
      if (wins != null && wins.isNotEmpty) {
        if (wins.contains(pos)) {
          WinType? winType = NumberUtil.toEnum(WinType.values, pos);
          if (winType != null) {
            logger.i('participant:$index win:$winType');
          }

          return winType;
        }
      }
    }

    return null;
  }

  MahjongActionStrategy actionStrategy = MahjongActionStrategy();

  /// 对打出的牌判断是否杠牌
  RoomEventAction discardBarDecide(Tile discardTile) {
    if (actionStrategy.winGoals.contains(WinType.pair7) ||
        actionStrategy.winGoals.contains(WinType.luxPair7) ||
        actionStrategy.winGoals.contains(WinType.thirteenOne)) {
      return RoomEventAction.pass;
    }
    int pos = handPile.tiles.indexOf(discardTile);
    if (pos == -1) {
      return RoomEventAction.pass;
    }
    if (pos + 1 >= handPile.tiles.length &&
        handPile.tiles[pos + 1] != discardTile) {
      return RoomEventAction.pass;
    }
    if (pos + 2 >= handPile.tiles.length) {
      return RoomEventAction.touch;
    }
    if (discardTile.next(handPile.tiles[2]) ||
        discardTile.gap(handPile.tiles[2])) {
      return RoomEventAction.pass;
    }
    if (discardTile == handPile.tiles[2]) {
      if (pos + 3 < handPile.tiles.length) {
        if (discardTile.next(handPile.tiles[3]) ||
            discardTile.gap(handPile.tiles[3])) {
          return RoomEventAction.touch;
        }
      }
      if (pos - 1 >= 0) {
        if (handPile.tiles[pos - 1].next(discardTile) ||
            handPile.tiles[pos - 1].gap(discardTile)) {
          return RoomEventAction.touch;
        }
      }
      return RoomEventAction.bar;
    }
    if (pos - 1 >= 0) {
      if (handPile.tiles[pos - 1].next(discardTile) ||
          handPile.tiles[pos - 1].gap(discardTile)) {
        return RoomEventAction.pass;
      }
    }

    return RoomEventAction.touch;
  }

  /// 摸牌判断是否杠牌
  RoomEventAction drawBarDecide(Tile drawTile) {
    if (actionStrategy.winGoals.contains(WinType.pair7) ||
        actionStrategy.winGoals.contains(WinType.luxPair7) ||
        actionStrategy.winGoals.contains(WinType.thirteenOne)) {
      return RoomEventAction.pass;
    }
    List<TypePile> touchPiles = handPile.touchPiles;
    if (touchPiles.isNotEmpty) {
      for (var touchPile in touchPiles) {
        if (touchPile.tiles.first == drawTile) {
          for (var tile in handPile.tiles) {
            if (tile.next(drawTile) ||
                tile.gap(drawTile) ||
                drawTile.next(tile) ||
                drawTile.gap(tile)) {
              return RoomEventAction.pass;
            }
          }

          return RoomEventAction.bar;
        }
      }
    }

    int pos = handPile.tiles.indexOf(drawTile);
    if (pos == -1) {
      return RoomEventAction.pass;
    }
    if (pos + 1 < handPile.tiles.length &&
        handPile.tiles[pos + 1] != drawTile) {
      return RoomEventAction.pass;
    }
    if (pos + 2 < handPile.tiles.length &&
        handPile.tiles[pos + 2] != drawTile) {
      return RoomEventAction.pass;
    }
    if (pos - 1 >= 0) {
      if (handPile.tiles[pos - 1].next(drawTile) ||
          handPile.tiles[pos - 1].gap(drawTile)) {
        return RoomEventAction.pass;
      }
    }
    if (pos + 3 < handPile.tiles.length) {
      if (drawTile.next(handPile.tiles[3]) || drawTile.gap(handPile.tiles[3])) {
        return RoomEventAction.pass;
      }
    }

    return RoomEventAction.darkBar;
  }

  /// 摸牌后的重要性评分
  Map<Tile, int> drawScore() {
    /// 首先判断是否有碰牌和杠牌，如果是wind，目标是混一色，混碰或者19碰
    List<TypePile> touchPiles = handPile.touchPiles;
    // 是否全是19牌刻子
    bool is19 = true;
    // 是否有wind牌刻子
    bool isWind = false;
    // 刻子的花色
    Suit? suit;

    actionStrategy.winGoals.clear();
    actionStrategy.suitGoal = null;
    // 检查刻子牌
    if (touchPiles.isNotEmpty) {
      for (var touchPile in touchPiles) {
        Tile tile = touchPile.tiles.first;
        if (!tile.is19()) {
          is19 = false;
        }
        Suit tileSuit = tile.suit;
        if (tileSuit == Suit.wind) {
          isWind = true;
        } else {
          if (suit == null) {
            suit = tileSuit;
          } else {
            if (suit != tileSuit) {
              actionStrategy.winGoals.add(WinType.touch);
            }
          }
        }
      }
      if (is19) {
        actionStrategy.winGoals.add(WinType.oneNine);
      }
      if (!actionStrategy.winGoals.contains(WinType.touch)) {
        actionStrategy.winGoals.add(WinType.mixOneType);
        actionStrategy.winGoals.add(WinType.mixTouch);
        if (!isWind) {
          actionStrategy.winGoals.add(WinType.pureTouch);
          actionStrategy.winGoals.add(WinType.pureOneType);
        }
        actionStrategy.suitGoal = suit;
      }
    }

    List<Tile> tiles = [...handPile.tiles];
    if (handPile.drawTile != null) {
      tiles.add(handPile.drawTile!);
      Pile.sortTile(tiles);
    }
    // 检查手牌，先格式化
    FormatPile formatPile = FormatPile(tiles: tiles);
    // 19牌的数量，如果大于7，则可能打13幺
    int count = formatPile.count19();
    if (count > 7 && actionStrategy.winGoals.isEmpty) {
      actionStrategy.winGoals.add(WinType.thirteenOne);
    }
    // 19牌的数量，如果大于7，则可能打19
    if (tiles.length - count < 6 && actionStrategy.winGoals.isEmpty) {
      actionStrategy.winGoals.add(WinType.oneNine);
    }
    // 打7对的检查
    count = formatPile.countPair();
    if (count > 3 && actionStrategy.winGoals.isEmpty) {
      actionStrategy.winGoals.add(WinType.pair7);
    }
    // 检查最多的花色
    if (actionStrategy.suitGoal == null) {
      Map<Suit, int> countSuit = formatPile.countSuit();
      Suit? maxSuit;
      int max = 0;
      for (var entry in countSuit.entries) {
        Suit suit = entry.key;
        if (suit == Suit.wind) {
          continue;
        }
        int count = entry.value;
        if (count > max) {
          max = count;
          maxSuit = suit;
        }
      }
      actionStrategy.winGoals.add(WinType.mixOneType);
      actionStrategy.winGoals.add(WinType.mixTouch);
      actionStrategy.winGoals.add(WinType.pureOneType);
      actionStrategy.winGoals.add(WinType.pureTouch);
      actionStrategy.suitGoal = maxSuit;
    }

    /// 计算重要性的评分，0-14
    /// 8-14:很重要，与最多花色相同，8表示19牌，9表示孤牌，10表示19相邻牌，11表示中间空心相邻牌，12表示中间带相邻牌，13表示对牌，14表示刻子或者顺子
    /// 1-7:不重要，不是最多花色
    /// 0:废牌
    /// 如果目标有19，19牌的评分上升到15-17，如果有7对，则非花色的对子评分将上升到13
    /// 如果目标有19，wind牌的评分上升到15-17，如果是混一色，单wind为8，对wind为11，三wind为14
    Map<Tile, int> scores = {};
    // 对每一种手牌评分
    int j = 0;
    for (int i = 0; i < tiles.length; i = i + j + 1) {
      Tile tile = tiles[i];
      if (actionStrategy.winGoals.contains(WinType.mixOneType) ||
          actionStrategy.winGoals.contains(WinType.mixTouch) ||
          actionStrategy.winGoals.contains(WinType.pureOneType) ||
          actionStrategy.winGoals.contains(WinType.pureTouch)) {
        int increment;
        if (tile.suit == actionStrategy.suitGoal) {
          increment = 8;
        } else {
          if (tile.suit == Suit.wind) {
            increment = 8;
          } else {
            increment = 0;
          }
        }
        scores[tile] = increment;
        if (tile.is19()) {
          scores[tile] = increment + 1;
        }
        if (i + 1 < tiles.length) {
          if (tile.gap(tiles[i + 1])) {
            scores[tile] = increment + 3;
            scores[tiles[i + 1]] = increment + 3;
            if (tile.is19() || tiles[i + 1].is19()) {
              scores[tile] = increment + 2;
              scores[tiles[i + 1]] = increment + 3;
            }
            j = 1;
          } else if (tile.next(tiles[i + 1])) {
            scores[tile] = increment + 4;
            scores[tiles[i + 1]] = increment + 4;
            if (tile.is19() || tiles[i + 1].is19()) {
              scores[tiles[i]] = increment + 2;
              scores[tiles[i + 1]] = increment + 2;
            }
            j = 1;
          } else if (tile == tiles[i + 1]) {
            scores[tile] = increment + 5;
            scores[tiles[i + 1]] = increment + 5;
            j = 1;
            if (i + 2 < tiles.length && tile == tiles[i + 2]) {
              scores[tile] = increment + 7;
              scores[tiles[i + 1]] = increment + 6;
              scores[tiles[i + 2]] = increment + 6;
              j = 2;
            }
          } else {
            scores[tile] = increment;
            j = 0;
          }
        }
      }
      if (actionStrategy.winGoals.contains(WinType.pair7)) {
        if (i + 1 < tiles.length && tile == tiles[i + 1]) {
          scores[tile] = 15;
          scores[tiles[i + 1]] = 15;
          if (tile.is19() || tile.suit == actionStrategy.suitGoal) {
            scores[tile] = 16;
            scores[tiles[i + 1]] = 16;
          }
          j = 1;
        } else {
          j = 0;
        }
      }
      if (actionStrategy.winGoals.contains(WinType.thirteenOne)) {
        if (tile.is19()) {
          scores[tile] = 15;
        }
        if (i + 1 < tiles.length && tile == tiles[i + 1]) {
          scores[tiles[i + 1]] = 1;
          j = 1;
          if (i + 2 < tiles.length && tile == tiles[i + 2]) {
            scores[tiles[i + 2]] = 1;
            j = 2;
          }
        } else {
          j = 0;
        }
      }
      if (actionStrategy.winGoals.contains(WinType.oneNine)) {
        if (tile.is19()) {
          scores[tile] = 15;
        }
        if (i + 1 < tiles.length && tile == tiles[i + 1]) {
          scores[tile] = 16;
          scores[tiles[i + 1]] = 16;
          j = 1;
          if (i + 2 < tiles.length && tile == tiles[i + 2]) {
            scores[tile] = 17;
            scores[tiles[i + 1]] = 17;
            scores[tiles[i + 2]] = 17;
            j = 2;
          }
        } else {
          j = 0;
        }
      }
    }

    return scores;
  }

  /// 查找最小重要性评分的牌
  Tile minTile(Map<Tile, int> scores) {
    Tile discardTile = handPile.tiles[0];
    int min = scores[discardTile] ?? 16;
    for (int i = 1; i < handPile.tiles.length; ++i) {
      Tile handTile = handPile.tiles[i];
      int score = scores[handTile] ?? 16;
      if (score < min) {
        min = score;
        discardTile = handTile;
      }
    }
    if (handPile.drawTile != null) {
      int score = scores[handPile.drawTile] ?? 16;
      if (score < min) {
        min = score;
        discardTile = handPile.drawTile!;
      }
    }

    return discardTile;
  }

  robotDiscard() {
    if (participant.robot && outstandingActions.isEmpty) {
      Future.delayed(Duration(seconds: 1), () {
        Map<Tile, int> scores = drawScore();
        Tile discardTile = minTile(scores);
        if (canDiscard() && handPile.exist(discardTile)) {
          // logger.i('participant:$index decide to discard tile:$discardTile');
          round.discard(index, discardTile);
        }
      });
    }

    mahjongFlameGame.reload();
  }
}
