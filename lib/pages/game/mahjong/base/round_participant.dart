import 'dart:async';

import 'package:colla_chat/pages/game/mahjong/base/format_tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/hand_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/mahjong_action.dart';
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

class MahjongActionValue {
  final MahjongAction action;
  final int bar;
  final int discard;

  MahjongActionValue(this.action, this.bar, this.discard);
}

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
  final RxMap<MahjongAction, Set<int>> outstandingActions =
      RxMap<MahjongAction, Set<int>>({});

  /// 参与者已经发生的行为，比如，明杠，暗杠等，值数组代表行为的发生人
  /// key和value相同，代表自摸杠，否则表示value打牌，key杠
  final Map<MahjongAction, Set<MahjongActionValue>> earnedActions =
      <MahjongAction, Set<MahjongActionValue>>{};

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

  bool canDiscard() {
    return handCount == 14;
  }

  addOutstandingAction(MahjongAction outstandingAction, List<int> vs) {
    Set<int>? values = outstandingActions[outstandingAction];
    if (values == null) {
      values = {};
      outstandingActions[outstandingAction] = values;
    }
    values.addAll(vs);
  }

  addEarnedAction(
      MahjongAction earnedAction, List<MahjongActionValue> earnedActionValues) {
    Set<MahjongActionValue>? values = earnedActions[earnedAction];
    if (values == null) {
      values = {};
      earnedActions[earnedAction] = values;
    }
    values.addAll(earnedActionValues);
  }

  /// 摸牌，有三种摸牌，普通的自摸，海底捞的自摸，杠上自摸
  /// owner摸到tile牌，dealTileType表示摸牌的方式
  Map<MahjongAction, Set<int>>? deal(
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

    if (handPile.exist(tile)) {
      logger.e('participant:$index draw tile:$tile is exist');
      return null;
    }

    handPile.drawTile = tile;
    handPile.drawTileType = dealTileType;
    logger.w('participant:$index draw tile:$tile successfully');

    /// 检查摸到的牌，看需要采取的动作，这里其实只需要摸牌检查
    Map<MahjongAction, Set<int>> outstandingActions =
        check(tile: tile, dealTileType: dealTileType);

    if (outstandingActions.isEmpty) {
      _robotDiscard();
    }
    mahjongFlameGame.reload();

    return outstandingActions;
  }

  /// 打牌，owner打出牌card，对其他人检查打的牌是否能够胡牌，杠牌和碰牌，返回检查的结果
  /// -1:owner不对，0:数目不对,
  MahjongActionResult discard(int owner, Tile tile) {
    if (owner != index) {
      return MahjongActionResult.match;
    }
    if (!canDiscard()) {
      logger.e('participant:$index owner:$owner can not discard:$tile');

      return MahjongActionResult.count;
    }
    if (!handPile.exist(tile)) {
      logger.e('participant:$index owner:$owner is not exist discard:$tile');

      return MahjongActionResult.exist;
    }
    wastePile.tiles.add(tile);
    logger.i('participant:$index owner:$owner wastePile add discard:$tile');

    return handPile.discard(tile);
  }

  /// 检查行为状态，既包括摸牌检查，也包含打牌检查，还包含机器人自动处理
  Map<MahjongAction, Set<int>> check(
      {required Tile tile, DealTileType? dealTileType}) {
    outstandingActions.clear();
    if (dealTileType == DealTileType.sea) {
      WinType? winType = handPile.checkWin(tile: tile);
      if (winType != null) {
        addOutstandingAction(MahjongAction.win, [winType.index]);
      } else {
        addOutstandingAction(MahjongAction.pass, []);
      }
      return outstandingActions.value;
    }

    /// 可以胡牌
    WinType? winType = handPile.checkWin(tile: tile);
    if (winType != null) {
      addOutstandingAction(MahjongAction.win, [winType.index]);
    }

    /// 摸牌检查
    if (tile == handPile.drawTile) {
      /// 摸牌检查暗杠牌
      List<int>? pos = handPile.checkDarkBar();
      if (pos != null) {
        addOutstandingAction(MahjongAction.darkBar, pos);
      }

      /// 摸牌检查明杠牌
      pos = handPile.checkDrawBar();
      if (pos != null) {
        addOutstandingAction(MahjongAction.bar, pos);
      }
    } else {
      /// 打牌检查杠牌
      int? pos = handPile.checkDiscardBar(tile);
      if (pos != null) {
        addOutstandingAction(MahjongAction.bar, [pos]);
      }

      /// 打牌检查碰牌
      pos = handPile.checkTouch(tile);
      if (pos != null) {
        addOutstandingAction(MahjongAction.touch, [pos]);
      }
    }

    logger.w(
        'participant:$index check tile:$tile, outstandingAction:${outstandingActions.value}');

    _robotCheck();

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
      addOutstandingAction(MahjongAction.win, [winType.index]);
    }

    return winType;
  }

  /// 当机器参与者有未决的行为时，自动采取行为
  _robotCheck() {
    if (!participant.robot) {
      return;
    }
    Map<MahjongAction, Set<int>> outstandingActions =
        this.outstandingActions.value;
    if (outstandingActions.isEmpty) {
      return;
    }
    Room room = round.room;
    int owner = index;
    Set<int>? pos = outstandingActions[MahjongAction.win];
    if (pos != null) {
      room.startRoomEvent(RoomEvent(room.name,
          roundId: round.id,
          owner: owner,
          action: RoomEventAction.win,
          pos: pos.first));
    }

    pos = outstandingActions[MahjongAction.darkBar];
    if (pos != null) {
      Tile? tile = handPile.drawTile;
      if (tile != null) {
        MahjongAction mahjongAction = drawBarDecide(tile);
        if (mahjongAction == MahjongAction.darkBar) {
          room.startRoomEvent(RoomEvent(room.name,
              roundId: round.id,
              owner: owner,
              action: RoomEventAction.darkBar,
              pos: pos.first));
        }
      }
    }
    pos = outstandingActions[MahjongAction.bar];
    if (pos != null) {
      MahjongAction? mahjongAction;
      Tile? tile = handPile.drawTile;
      if (tile != null) {
        mahjongAction = drawBarDecide(tile);
      } else {
        tile = round.discardTile;
        if (tile != null) {
          mahjongAction = discardBarDecide(tile);
        }
      }
      if (mahjongAction == MahjongAction.bar) {
        room.startRoomEvent(RoomEvent(room.name,
            roundId: round.id,
            owner: owner,
            action: RoomEventAction.bar,
            pos: pos.first));
      }
    }

    pos = outstandingActions[MahjongAction.touch];
    if (pos != null) {
      Tile? tile = round.discardTile;
      if (tile != null) {
        MahjongAction mahjongAction = discardBarDecide(tile);
        if (mahjongAction == MahjongAction.touch) {
          room.startRoomEvent(RoomEvent(room.name,
              roundId: round.id,
              owner: owner,
              action: RoomEventAction.touch,
              src: round.discardParticipant,
              tile: round.discardTile,
              pos: pos.first));
        }
      }
    }

    this.outstandingActions.clear();
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
  Tile? touch(int owner, int pos, int discardParticipant, Tile tile) {
    if (index != owner) {
      return null;
    }
    Tile? touchTile = handPile.touch(pos, tile);
    if (touchTile != null && handPile.touchPiles.length == 4) {
      packer = discardParticipant;
    }
    _robotDiscard();

    return touchTile;
  }

  /// 打牌杠牌discardBar
  Tile? discardBar(int owner, int pos, Tile tile, int discardParticipant) {
    if (index != owner) {
      return null;
    }
    Tile? discardBarTile = handPile.discardBar(pos, tile, discardParticipant);
    if (discardBarTile != null) {
      addEarnedAction(MahjongAction.bar, [
        MahjongActionValue(MahjongAction.bar, owner, discardParticipant),
      ]);
    }
    if (handPile.touchPiles.length == 4) {
      packer = discardParticipant;
    }
    _robotDiscard();

    return discardBarTile;
  }

  /// 摸牌杠牌和手牌杠牌drawBar
  /// owner明杠位置，pos的值分两种情况，摸牌杠牌和手牌杠牌
  /// 摸牌杠牌和手牌杠牌:pos为-1，表示是摸牌可杠，否则表示手牌可杠的位置
  Tile? drawBar(int owner, int pos, {Tile? tile}) {
    if (index != owner) {
      return null;
    }
    tile = handPile.drawBar(pos, owner, tile: tile);
    if (tile != null) {
      addEarnedAction(MahjongAction.bar, [
        MahjongActionValue(MahjongAction.bar, owner, owner),
      ]);
    }

    _robotDiscard();

    return tile;
  }

  /// 暗杠牌，owner杠手上pos位置已有的四张牌（tile==null）或者新进的tile（tile!=null）
  Tile? darkBar(int owner, int pos) {
    if (index != owner) {
      return null;
    }
    Tile? tile = handPile.darkBar(pos, owner);
    if (tile != null) {
      addEarnedAction(MahjongAction.darkBar, [
        MahjongActionValue(MahjongAction.darkBar, owner, owner),
      ]);
    }

    _robotDiscard();

    return tile;
  }

  /// 吃牌，owner在pos位置吃上家的牌card
  Tile? chow(int owner, int pos, Tile tile) {
    if (index == owner) {
      Tile? c = handPile.chow(pos, tile);

      return c;
    }

    return null;
  }

  /// 胡牌，owner胡participantState中的可胡的牌形,pos表示可胡牌形数组的位置
  WinType? win(int owner, int win) {
    if (index == owner) {
      Set<int>? wins = outstandingActions[MahjongAction.win];
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
      Set<int>? wins = outstandingActions[MahjongAction.win];
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
  MahjongAction discardBarDecide(Tile discardTile) {
    if (actionStrategy.winGoals.contains(WinType.pair7) ||
        actionStrategy.winGoals.contains(WinType.luxPair7) ||
        actionStrategy.winGoals.contains(WinType.thirteenOne)) {
      return MahjongAction.pass;
    }
    int pos = handPile.tiles.indexOf(discardTile);
    if (pos == -1) {
      return MahjongAction.pass;
    }
    if (pos + 1 >= handPile.tiles.length &&
        handPile.tiles[pos + 1] != discardTile) {
      return MahjongAction.pass;
    }
    if (pos + 2 >= handPile.tiles.length) {
      return MahjongAction.touch;
    }
    if (discardTile.next(handPile.tiles[2]) ||
        discardTile.gap(handPile.tiles[2])) {
      return MahjongAction.pass;
    }
    if (discardTile == handPile.tiles[2]) {
      if (pos + 3 < handPile.tiles.length) {
        if (discardTile.next(handPile.tiles[3]) ||
            discardTile.gap(handPile.tiles[3])) {
          return MahjongAction.touch;
        }
      }
      if (pos - 1 >= 0) {
        if (handPile.tiles[pos - 1].next(discardTile) ||
            handPile.tiles[pos - 1].gap(discardTile)) {
          return MahjongAction.touch;
        }
      }
      return MahjongAction.bar;
    }
    if (pos - 1 >= 0) {
      if (handPile.tiles[pos - 1].next(discardTile) ||
          handPile.tiles[pos - 1].gap(discardTile)) {
        return MahjongAction.pass;
      }
    }

    return MahjongAction.touch;
  }

  /// 摸牌判断是否杠牌
  MahjongAction drawBarDecide(Tile drawTile) {
    if (actionStrategy.winGoals.contains(WinType.pair7) ||
        actionStrategy.winGoals.contains(WinType.luxPair7) ||
        actionStrategy.winGoals.contains(WinType.thirteenOne)) {
      return MahjongAction.pass;
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
              return MahjongAction.pass;
            }
          }

          return MahjongAction.bar;
        }
      }
    }

    int pos = handPile.tiles.indexOf(drawTile);
    if (pos == -1) {
      return MahjongAction.pass;
    }
    if (pos + 1 < handPile.tiles.length &&
        handPile.tiles[pos + 1] != drawTile) {
      return MahjongAction.pass;
    }
    if (pos + 2 < handPile.tiles.length &&
        handPile.tiles[pos + 2] != drawTile) {
      return MahjongAction.pass;
    }
    if (pos - 1 >= 0) {
      if (handPile.tiles[pos - 1].next(drawTile) ||
          handPile.tiles[pos - 1].gap(drawTile)) {
        return MahjongAction.pass;
      }
    }
    if (pos + 3 < handPile.tiles.length) {
      if (drawTile.next(handPile.tiles[3]) || drawTile.gap(handPile.tiles[3])) {
        return MahjongAction.pass;
      }
    }

    return MahjongAction.darkBar;
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
    Tile? discardTile;
    int min = 15;
    for (int i = 1; i < handPile.tiles.length; ++i) {
      Tile handTile = handPile.tiles[i];
      int score = scores[handTile] ?? 0;
      if (score < min) {
        min = score;
        discardTile = handTile;
      }
    }

    return discardTile!;
  }

  _robotDiscard() {
    if (participant.robot) {
      Map<Tile, int> scores = drawScore();
      Tile discardTile = minTile(scores);
      if (canDiscard() && handPile.exist(discardTile)) {
        logger.i('participant:$index decide to discard tile:$discardTile');
        round.discard(index, discardTile);
      }
    }
  }
}
