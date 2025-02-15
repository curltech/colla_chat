import 'dart:async';
import 'dart:math';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/game/mahjong/base/format_tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/full_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/hand_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_event.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_pool.dart';
import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/stock_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/number_util.dart';

/// 摸牌的类型：自摸牌，杠上牌，海底捞
enum DealTileType { self, bar, sea }

/// 打牌的令牌
class DiscardToken {
  /// 刚出牌的参与者
  int discardParticipant;

  /// 出牌
  Tile discardTile;

  /// 被参与者采取了行为
  RoomEventAction? action;

  /// 采取了行为的参与者
  int? actionParticipant;

  DiscardToken(this.discardParticipant, this.discardTile);
}

/// 每一轮，每轮有四个轮参与者
class Round {
  /// 每轮的编号，在房间中按次序增长
  int id;

  /// 所属的房间
  late final Room room;

  /// 未使用的牌，如果是banker，则不为null，否则为null，用于区分是否是banker
  StockPile? stockPile;

  final List<RoundParticipant> roundParticipants = [];

  /// 庄家，对每一轮来说，banker拥有所有的数据，包括每一个参与者的handPile和stockPile
  /// 对非banker来说，每一个参与者的handPile和stockPile都是unknownCard
  /// 应用的事件模型是所有的消息都发送给banker，然后banker再转发给其他的参与者
  int banker;

  /// 记录事件
  final List<RoomEvent> roomEvents = [];

  /// 当参与者打牌或者明杠的时候，creator需要等待其他参与者的回复事件
  /// creator只有等到其他参与者的回复事件后才能决定下一步的处理
  /// 比如打牌的时候，creator等待所有的参与者的回复，才决定是继续发牌还是有人胡牌或者杠牌
  /// Set<int>为等待回复的参与者
  Map<int, Set<int>> outstandingParticipants = {};

  /// 出牌的令牌，创建者发牌设置为空，打牌的参与者设置为打出的牌
  /// 只有为空的时候才可以打牌
  DiscardToken? discardToken;

  /// 同圈放弃的胡牌
  int? discardWin;
  Tile? discardWinTile;

  int? robber;
  Tile? robCard;

  Round(this.id, this.room, this.banker, {int? owner, HandPile? handPile}) {
    for (int i = 0; i < room.participants.length; ++i) {
      Participant participant = room.participants[i];
      RoundParticipant roundParticipant =
          RoundParticipant(i, this, participant);
      roundParticipants.add(roundParticipant);
    }

    if (owner == null && handPile == null) {
      init();
    } else {
      for (int i = 0; i < roundParticipants.length; ++i) {
        if (i == owner) {
          roundParticipants[i].handPile.tiles = handPile!.tiles;
        } else {
          roundParticipants[i].handPile.tiles = [];
          for (int j = 0; j < 13; ++j) {
            roundParticipants[i].handPile.tiles.add(unknownTile);
          }
        }
      }
    }
  }

  Round.fromJson(Map json)
      : id = json['id'],
        banker = json['banker'] {
    String? name = json['name'];
    if (name != null) {
      Room? room = roomPool.get(name);
      if (room != null) {
        this.room = room;
        List? roundParticipants = json['roundParticipants'];
        if (roundParticipants != null && roundParticipants.isNotEmpty) {
          for (int i = 0; i < roundParticipants.length; ++i) {
            RoundParticipant roundParticipant = roundParticipants[i];
            this.roundParticipants.add(roundParticipant);
          }
        }
      } else {
        throw 'New round failure, room name:$name is not exist';
      }
    }
  }

  Map<String, dynamic> toJson(int owner) {
    return {
      'id': id,
      'name': room.name,
      'banker': banker,
      'roundParticipants': JsonUtil.toJson(roundParticipants),
    };
  }

  init() {
    List<Tile> stockTiles = [
      ...fullPile.tiles.values,
    ];
    stockPile = StockPile();
    Random random = Random.secure();

    /// 牌的总数是136
    for (int i = 0; i < 136; ++i) {
      int pos = random.nextInt(stockTiles.length);
      Tile tile = stockTiles.removeAt(pos);

      /// 每个参与者发13张牌
      if (i < 52) {
        int reminder = (i + banker) % 4;
        roundParticipants[reminder].handPile.tiles.add(tile);
      } else {
        stockPile!.tiles.add(tile);
      }
    }

    /// 手牌排序
    for (var roundParticipant in roundParticipants) {
      roundParticipant.handPile.sort();
    }
  }

  /// stockPile不为空，则是creator
  bool get isCreator {
    return room.creator == room.currentParticipant && stockPile != null;
  }

  RoundParticipant getRoundParticipant(
      ParticipantDirection participantDirection) {
    return roundParticipants[participantDirection.index];
  }

  /// 牌的总数
  int get total {
    int total = 0;
    for (int i = 0; i < roundParticipants.length; ++i) {
      total += roundParticipants[i].total;
    }
    return total + stockPile!.tiles.length;
  }

  /// 增加等待决策的参与者
  addOutstandingParticipants(int src, List<int> participants) {
    Set<int>? ps = outstandingParticipants[src];
    if (ps == null) {
      ps = {};
      outstandingParticipants[src] = ps;
    }
    for (int participant in participants) {
      ps.add(participant);
    }
  }

  /// 消解并检查等待的事件，如果全部消解则返回true，否则，返回false
  bool checkOutstandingParticipant(int src, int participant) {
    Set<int>? ps = outstandingParticipants[src];
    if (ps != null) {
      if (ps.contains(participant)) {
        ps.remove(participant);
        RoomEvent outstandingRoomEvent = RoomEvent(room.name,
            roundId: id,
            owner: participant,
            content: outstandingParticipants.values.firstOrNull?.toList(),
            action: RoomEventAction.checkOutstanding);
        roomEvents.add(outstandingRoomEvent);
      }
      if (ps.isEmpty) {
        outstandingParticipants.remove(src);
        return true;
      }
    } else {
      return false;
    }

    return false;
  }

  bool get isSeaTake {
    return stockPile!.tiles.length < 5;
  }

  List<int> _getParticipantIndexes() {
    return roundParticipants.map((RoundParticipant roundParticipant) {
      return roundParticipant.index;
    }).toList();
  }

  /// 下面所有的事件命令函数，非_打头的是发起的参与者的直接调用的执行函数
  /// _打头的是通过消息接收到的其他参与者发起的事件

  /// creator发牌，只能是creator才能执行，把牌发给打牌人discard的下一家或者banker
  Future<Tile?> deal({int? discardParticipant}) async {
    int? owner;
    if (discardParticipant != null) {
      owner = room.next(discardParticipant);
    } else {
      owner = banker;
    }
    if (!isCreator) {
      logger.e('owner:$owner deal tile failure, not creator');
      return null;
    }
    Tile? first = stockPile!.tiles.firstOrNull;
    if (first == null) {
      logger.e('owner:$owner deal tile failure, stockPile is empty');
      return null;
    }

    DealTileType dealTileType = DealTileType.self;
    if (isSeaTake) {
      dealTileType = DealTileType.sea;
    }
    Tile tile = stockPile!.tiles.removeLast();

    logger.w(
        'owner:$owner deal tile:$tile, dealTileType:$dealTileType successfully, leave ${stockPile!.tiles.length} tiles');

    /// 发消息给所有人，包括自己
    RoomEvent tileRoomEvent = RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.deal,
        tile: tile,
        src: room.creator,
        pos: dealTileType.index);
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i == owner || i == room.creator) {
        await _sendChatMessage(tileRoomEvent, room.creator, [i]);
      } else {
        RoomEvent unknownRoomEvent = RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.deal,
            tile: unknownTile,
            src: room.creator,
            pos: dealTileType.index);
        await _sendChatMessage(unknownRoomEvent, room.creator, [i]);
      }
    }

    return tile;
  }

  /// 收到发的牌tile的消息
  Tile? _deal(int owner, Tile tile, int dealTileTypeIndex, int receiver) {
    RoundParticipant roundParticipant = roundParticipants[owner];
    logger.w(
        'receive:$receiver chat message owner:$owner deal tile:$tile, dealTileTypeIndex:$dealTileTypeIndex successfully');
    Map<RoomEventAction, Set<int>>? outstandingActions =
        roundParticipant.deal(owner, tile, dealTileTypeIndex);
    if (outstandingActions == null) {
      return null;
    }

    return tile;
  }

  /// 主动打牌，owner表示打牌的参与者，receiver代表接收到事件的参与者
  /// 返回值是true，表示打的牌没有需要等待的处理，可以发牌
  /// 否则，表示有需要等待的处理
  Future<void> discard(int owner, Tile tile) async {
    List<int> receivers = _getParticipantIndexes();
    // logger.w(
    //     'owner:$owner send chat message to receivers:${receivers} discard tile:$tile');
    RoomEvent discardRoomEvent = RoomEvent(room.name,
        roundId: id,
        owner: owner,
        src: owner,
        action: RoomEventAction.discard,
        tile: tile);
    await _sendChatMessage(discardRoomEvent, owner, receivers);
  }

  /// 收到owner打牌的消息
  Future<RoomEventActionResult> _discard(
      int owner, Tile tile, int receiver) async {
    // logger.w('receiver:receiver receive chat message owner:$owner discard tile:$tile');

    /// 打牌的参与者执行事件处理
    final RoundParticipant roundParticipant = roundParticipants[owner];
    RoomEventActionResult result = roundParticipant.discard(owner, tile);
    if (result == RoomEventActionResult.error) {
      logger.e('owner:$owner discard tile $tile failure:${result.name}');

      return result;
    }
    discardToken = DiscardToken(owner, tile);
    // logger.w(
    //     'owner:$owner discard tile:$tile successfully, discardParticipant:${discardToken!.discardParticipant}, discardTile:${discardToken!.discardTile}');

    /// 接收别人打牌的消息的是创建者，等待检查其他的参与者的决策
    if (receiver == room.creator) {
      /// 事件消息的接收者是creator，检查，发消息给其他参与者，2个消息，等待2个事件
      for (int i = 0; i < roundParticipants.length; ++i) {
        if (i != owner) {
          addOutstandingParticipants(owner, [i]);
        }
      }
      List<int>? ps = outstandingParticipants.values.firstOrNull?.toList();
      RoomEvent outstandingRoomEvent = RoomEvent(room.name,
          roundId: id,
          owner: owner,
          tile: tile,
          content: ps,
          action: RoomEventAction.outstanding);
      roomEvents.add(outstandingRoomEvent);
    }

    /// 别人的打牌自己检查是否需要决策
    if (owner != receiver) {
      Map<RoomEventAction, Set<int>> outstandingActions =
          roundParticipants[receiver].check(owner, tile);
      if (outstandingActions.isNotEmpty) {
        result = RoomEventActionResult.check;
        addOutstandingParticipants(owner, [receiver]);
      }
    }

    return result;
  }

  Future<void> pass(int owner, Tile tile, int src, {int? pos}) async {
    List<int> receivers = _getParticipantIndexes();
    RoomEvent passRoomEvent = RoomEvent(room.name,
        roundId: id,
        owner: owner,
        src: src,
        tile: tile,
        pos: pos,
        action: RoomEventAction.pass);
    await _sendChatMessage(passRoomEvent, owner, receivers);
  }

  /// 收到owner pass的消息
  _pass(int owner, Tile tile, int src, int receiver, {int? pos}) async {
    logger.w(
        'receiver:$receiver chat message: owner:$owner, tile:$tile, src:$src, pos:$pos, isSeaTake:$isSeaTake pass');
    final RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.pass(owner);

    if (receiver == room.creator) {
      bool pass = checkOutstandingParticipant(src, owner);
      if (pass) {
        await deal(discardParticipant: src);
      }
    } else {
      checkOutstandingParticipant(src, owner);
    }
  }

  /// 某个参与者碰打出的牌
  Future<void> touch(int owner, int pos, int src, Tile discardTile) async {
    if (discardToken == null) {
      logger.e('owner:$owner touch, but discardToken is null');

      return;
    }
    if (discardToken!.action != null) {
      logger.e('owner:$owner touch, but discardToken action is not null');

      return;
    }
    if (discardTile != discardToken!.discardTile) {
      logger.e('owner:$owner touch, but discardTile:$discardTile is not equal');

      return;
    }

    if (discardToken!.discardParticipant != src) {
      logger.e(
          'owner:$owner touch, but discardParticipant is not equal src:$src');

      return;
    }

    List<int> receivers = _getParticipantIndexes();
    RoomEvent touchRoomEvent = RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.touch,
        tile: discardTile,
        pos: pos,
        src: src);
    await _sendChatMessage(touchRoomEvent, owner, receivers);
  }

  Future<TypePile?> _touch(
      int owner, int pos, int src, Tile discardTile, int receiver) async {
    if (discardToken == null) {
      logger.e('owner:$owner touch, but discardToken is null');

      return null;
    }
    if (discardToken!.action != null) {
      logger.e('owner:$owner touch, but discardToken action is not null');

      return null;
    }
    if (discardTile != discardToken!.discardTile) {
      logger.e(
          'owner:$owner touch, but discardToken discardTile:$discardTile is not equal');

      return null;
    }
    if (discardToken!.discardParticipant != src) {
      logger.e(
          'owner:$owner touch, but discardToken discardParticipant is not equal src:$src');

      return null;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    TypePile? typePile = roundParticipant.touch(owner, pos, src, discardTile);
    if (typePile == null) {
      return null;
    }
    List<Tile> tiles = roundParticipants[src].wastePile.tiles;
    if (tiles.isNotEmpty && discardTile == tiles.last) {
      tiles.removeLast();
    }
    discardToken!.action = RoomEventAction.touch;
    discardToken!.actionParticipant = owner;
    if (receiver == room.creator) {
      outstandingParticipants.clear();
    }

    roundParticipant.robotDiscard(owner, discardTile);

    return typePile;
  }

  int get barCount {
    int c = 0;
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      List<Set<RoomEvent>> counts =
          roundParticipant.earnedActions.values.toList();
      for (var count in counts) {
        c += count.length;
      }
    }

    return c;
  }

  /// 某个参与者明杠牌，pos表示可杠的手牌的位置
  Future<void> bar(int owner, int pos, {Tile? tile, int? src}) async {
    List<int> receivers = _getParticipantIndexes();
    RoomEvent barRoomEvent = RoomEvent(room.name,
        roundId: id,
        owner: owner,
        src: src,
        tile: tile,
        action: RoomEventAction.bar,
        pos: pos);
    await _sendChatMessage(barRoomEvent, owner, receivers);
  }

  /// 收到owner杠牌的消息
  /// 明杠牌，分三种情况，打牌杠牌，摸牌杠牌和手牌杠牌
  /// 打牌杠牌:返回值为杠的牌，为空表示未成功
  /// 摸牌杠牌和手牌杠牌:pos为-1，表示是摸牌可杠，否则表示手牌可杠的位置
  Future<TypePile?> _bar(int owner, int pos, int receiver,
      {Tile? tile, int? src}) async {
    logger.w('chat message: owner:$owner bar pos:$pos');
    RoundParticipant roundParticipant = roundParticipants[owner];
    TypePile? typePile;
    if (pos == -1) {
      roundParticipant.drawBar(owner, pos);
    } else if (pos > -1) {
      if (tile == null) {
        roundParticipant.drawBar(owner, pos);
      } else {
        typePile = roundParticipant.discardBar(owner, pos, tile, src!);
        if (typePile != null) {
          List<Tile> tiles = roundParticipants[src].wastePile.tiles;
          if (tiles.isNotEmpty && tile == tiles.last) {
            tiles.removeLast();
          }
          discardToken!.action = RoomEventAction.bar;
          discardToken!.actionParticipant = owner;
        }
      }
    }
    if (receiver == room.creator) {
      outstandingParticipants.clear();
    }
    await barDeal(owner);

    return typePile;
  }

  /// 杠牌发牌，只有creator才能调用
  Future<Tile?> barDeal(int owner) async {
    if (!isCreator) {
      logger.e('owner:$owner barDeal tile failure, not creator');
      return null;
    }
    Tile? first = stockPile?.tiles.firstOrNull;
    if (first == null) {
      logger.e('owner:$owner barDeal tile failure, stockPile is empty');
      return null;
    }

    int mod = barCount % 2;
    Tile tile;
    if (mod == 0 && stockPile!.tiles.length > 1) {
      tile = stockPile!.tiles.removeAt(stockPile!.tiles.length - 2);
    } else {
      tile = stockPile!.tiles.removeLast();
    }

    logger.w('barDeal tile $tile, leave ${stockPile!.tiles.length} tiles');

    RoomEvent tileRoomEvent = RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.deal,
        tile: tile,
        src: room.creator,
        pos: DealTileType.bar.index);
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i == owner || i == room.creator) {
        await _sendChatMessage(tileRoomEvent, room.creator, [owner]);
      } else {
        RoomEvent unknownRoomEvent = RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.deal,
            tile: unknownTile,
            src: room.creator,
            pos: DealTileType.bar.index);
        await _sendChatMessage(unknownRoomEvent, room.creator, [i]);
      }
    }

    return tile;
  }

  /// owner抢src的明杠牌card
  _rob(int owner, int src, Tile tile, {int? receiver}) {}

  /// 某个参与者暗杠，pos表示杠牌的位置
  Future<void> darkBar(int owner, int pos) async {
    RoomEvent barRoomEvent = RoomEvent(room.name,
        roundId: id,
        owner: owner,
        src: owner,
        action: RoomEventAction.darkBar,
        pos: pos);
    List<int> receivers = _getParticipantIndexes();
    await _sendChatMessage(barRoomEvent, owner, receivers);
  }

  Future<TypePile?> _darkBar(int owner, int pos, int receiver) async {
    logger.w('chat message: owner:$owner darkBar pos:$pos');
    RoundParticipant roundParticipant = roundParticipants[owner];
    TypePile? typePile = roundParticipant.darkBar(owner, pos);
    await barDeal(owner);

    return typePile;
  }

  /// 某个参与者吃打出的牌，pos表示吃牌的位置
  /// 暂时不实现这个功能
  Future<void> chow(int owner, int pos) async {
    RoomEvent barRoomEvent = RoomEvent(room.name,
        roundId: id, owner: owner, action: RoomEventAction.chow, pos: pos);
    List<int> receivers = _getParticipantIndexes();
    await _sendChatMessage(barRoomEvent, owner, receivers);
  }

  Future<TypePile?> _chow(int owner, int pos) async {
    if (discardToken == null) {
      return null;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    TypePile? typePile =
        roundParticipant.chow(owner, pos, discardToken!.discardTile);
    if (typePile == null) {
      return typePile;
    }

    roundParticipants[discardToken!.discardParticipant]
        .wastePile
        .tiles
        .removeLast();
    discardToken!.action = RoomEventAction.chow;
    discardToken!.actionParticipant = owner;
    await barDeal(owner);

    return typePile;
  }

  /// 胡牌计分
  bool _score(int owner, int winTypeIndex, int receiver) {
    WinType? winType = NumberUtil.toEnum(WinType.values, winTypeIndex);
    if (winType == null) {
      return false;
    }
    int? baseScore = room.completeTypeScores[winType];
    if (baseScore == null) {
      return false;
    }
    if (roundParticipants[receiver].participant.robot) {
      return false;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];

    /// 抢杠，owner是胡牌人，robber是被抢人
    if (robber != null && robCard != null) {
      roundParticipant.participant.score.value += baseScore * 3;
      roundParticipants[robber!].participant.score.value -= baseScore * 3;
    } else if (roundParticipant.handPile.drawTileType == DealTileType.bar ||
        roundParticipant.handPile.drawTileType == DealTileType.sea) {
      /// 杠上开花或者海底捞月
      baseScore = baseScore * 2;
      roundParticipant.participant.score.value += baseScore * 3;
    } else if (roundParticipant.handPile.drawTileType == DealTileType.self) {
      /// 自摸
      roundParticipant.participant.score.value += baseScore * 3;
    } else {
      /// 接别人打牌胡
      roundParticipant.participant.score.value += baseScore;
    }
    if (discardToken != null) {
      /// 打牌别人胡
      roundParticipants[discardToken!.discardParticipant]
          .participant
          .score
          .value -= baseScore;
    } else {
      if (roundParticipant.packer != null) {
        /// 包
        RoundParticipant pc = roundParticipants[roundParticipant.packer!];
        pc.participant.score.value -= 3 * baseScore;
      } else {
        /// 别人自摸
        for (int i = 0; i < roundParticipants.length; ++i) {
          if (i != owner) {
            RoundParticipant roundParticipant = roundParticipants[i];
            roundParticipant.participant.score.value -= baseScore;
          }
        }
      }
    }

    /// 杠牌的计算
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      for (var entry in roundParticipant.earnedActions.entries) {
        RoomEventAction roomEventAction = entry.key;

        /// 暗杠
        if (roomEventAction == RoomEventAction.darkBar) {
          Set<RoomEvent> roomEvents = entry.value;
          for (var roomEvent in roomEvents) {
            if (i == roomEvent.owner) {
              roundParticipant.participant.score.value += 60;
            } else {
              roundParticipant.participant.score.value -= 20;
            }
          }
        }

        /// 明杠
        if (roomEventAction == RoomEventAction.bar) {
          Set<RoomEvent> roomEvents = entry.value;
          for (var roomEvent in roomEvents) {
            // 自摸杠
            if (roomEvent.owner == roomEvent.src) {
              if (i == roomEvent.owner) {
                roundParticipant.participant.score.value += 30;
              } else {
                roundParticipant.participant.score.value -= 10;
              }
            } else {
              if (i == roomEvent.owner) {
                roundParticipant.participant.score.value += 30;
              } else if (i == roomEvent.src) {
                roundParticipant.participant.score.value -= 30;
              }
            }
          }
        }
      }
    }

    return true;
  }

  /// 某个参与者胡牌,pos表示胡牌的类型
  Future<void> win(int owner, int pos) async {
    WinType? winType = NumberUtil.toEnum(WinType.values, pos);
    if (winType == null) {
      return;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    if (!roundParticipant.participant.robot) {
      bool? confirm = await DialogUtil.confirm(
          content: 'owner:$owner, do you want win $winType?');
      if (confirm == null || !confirm) {
        return;
      }
    } else {
      DialogUtil.info(content: 'owner:$owner win $winType');
    }
    RoomEvent winRoomEvent = RoomEvent(room.name,
        roundId: id,
        owner: owner,
        src: owner,
        pos: pos,
        action: RoomEventAction.win);
    List<int> receivers = _getParticipantIndexes();
    await _sendChatMessage(winRoomEvent, owner, receivers);
  }

  Future<WinType?> _win(int owner, int pos, int receiver) async {
    RoundParticipant roundParticipant = roundParticipants[owner];
    WinType? winType = roundParticipant.win(owner, pos);
    if (winType == null) {
      return null;
    }

    _score(owner, winType.index, receiver);
    roundParticipant.isWin.value = true;
    if (receiver == room.creator) {
      room.banker = owner;
      // await room.startRoomEvent(RoomEvent(room.name,
      //     roundId: id, owner: owner, action: RoomEventAction.round));
    }

    return winType;
  }

  /// 作为creator，分发事件消息给其他参与者，不包括事件的原始发送者
  /// 否则，发送消息给creator
  _sendChatMessage(RoomEvent roomEvent, int sender, List<int> receivers) async {
    for (int receiver in receivers) {
      RoundParticipant roundParticipant = roundParticipants[receiver];
      roomEvent.sender = sender;
      roomEvent.receiver = receiver;
      ChatMessage chatMessage = await chatMessageService.buildChatMessage(
          receiverPeerId: roundParticipant.participant.peerId,
          subMessageType: ChatMessageSubType.mahjong,
          content: roomEvent);
      if (receiver == sender) {
        await roomPool.onRoomEvent(chatMessage);
      } else if (sender == room.creator) {
        if (roundParticipant.participant.robot) {
          await roomPool.onRoomEvent(chatMessage);
        } else {
          await roomPool.send(chatMessage);
        }
      } else if (roundParticipants[sender].participant.robot) {
        if (roundParticipant.participant.robot || receiver == room.creator) {
          await roomPool.onRoomEvent(chatMessage);
        } else {
          await roomPool.send(chatMessage);
        }
      } else {
        await roomPool.send(chatMessage);
      }
    }
  }

  Future<dynamic> startRoomEvent(RoomEvent roomEvent) async {
    dynamic returnValue;
    RoomEventAction? action = roomEvent.action;
    switch (action) {
      case RoomEventAction.deal:
        returnValue = await deal();
      case RoomEventAction.discard:
        await discard(roomEvent.owner, roomEvent.tile!);
      case RoomEventAction.bar:
        await bar(roomEvent.owner, roomEvent.pos!,
            tile: roomEvent.tile, src: roomEvent.src);
      case RoomEventAction.touch:
        await touch(
            roomEvent.owner, roomEvent.pos!, roomEvent.src!, roomEvent.tile!);
      case RoomEventAction.darkBar:
        await darkBar(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.chow:
        await chow(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.pass:
        await pass(roomEvent.owner, roomEvent.tile!, roomEvent.src!,
            pos: roomEvent.pos);
      case RoomEventAction.win:
        await win(roomEvent.owner, roomEvent.pos!);
      default:
        break;
    }

    mahjongFlameGame.reload();

    return returnValue;
  }

  /// roomEvent的receiver为空，则是直接调用，
  /// 否则是chatMessage消息方式调用，表示其他参与者发生事件，通知receiver
  /// 发送chatMessage事件消息，只能是creator发送到其他参与者，或者其他参与者发送给creator
  /// 在receiver为空的情况下:
  /// 假如自己是creator，则处理事件，然后分发事件消息到其他参与者
  /// 假如自己不是creator，则发送者是creator，则处理事件消息
  /// 在receiver不为空的情况下:
  /// 假如自己是creator，则处理事件，然后转发事件消息到其他参与者
  /// 假如自己不是creator，则不发送事件消息
  Future<dynamic> onRoomEvent(RoomEvent roomEvent) async {
    roomEvents.add(roomEvent);
    dynamic returnValue;
    RoomEventAction? action = roomEvent.action;
    switch (action) {
      case RoomEventAction.deal:
        returnValue = _deal(roomEvent.owner, roomEvent.tile!, roomEvent.pos!,
            roomEvent.receiver!);
      case RoomEventAction.discard:
        returnValue = await _discard(
            roomEvent.owner, roomEvent.tile!, roomEvent.receiver!);
      case RoomEventAction.bar:
        returnValue = await _bar(
            roomEvent.owner, roomEvent.pos!, roomEvent.receiver!,
            tile: roomEvent.tile, src: roomEvent.src);
      case RoomEventAction.barDeal:
        returnValue = await barDeal(roomEvent.owner);
      case RoomEventAction.touch:
        returnValue = await _touch(roomEvent.owner, roomEvent.pos!,
            roomEvent.src!, roomEvent.tile!, roomEvent.receiver!);
      case RoomEventAction.darkBar:
        returnValue = await _darkBar(
            roomEvent.owner, roomEvent.pos!, roomEvent.receiver!);
      case RoomEventAction.chow:
        returnValue = await _chow(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.rob:
        returnValue = _rob(roomEvent.owner, roomEvent.src!, roomEvent.tile!,
            receiver: roomEvent.receiver);
      case RoomEventAction.score:
        returnValue =
            _score(roomEvent.owner, roomEvent.pos!, roomEvent.receiver!);
      case RoomEventAction.pass:
        returnValue = await _pass(roomEvent.owner, roomEvent.tile!,
            roomEvent.src!, roomEvent.receiver!,
            pos: roomEvent.pos);
      case RoomEventAction.win:
        returnValue =
            await _win(roomEvent.owner, roomEvent.pos!, roomEvent.receiver!);
      default:
        break;
    }

    mahjongFlameGame.reload();

    return returnValue;
  }
}
