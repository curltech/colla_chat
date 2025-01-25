import 'dart:math';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/game/mahjong/base/full_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/hand_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/mahjong_action.dart';
import 'package:colla_chat/pages/game/mahjong/base/participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
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

  /// 最新的发牌的参与者，就是creator把牌发给drawer
  late int drawer;

  /// 当参与者打牌或者明杠的时候，creator需要等待其他参与者的回复事件
  /// creator只有等到其他参与者的回复事件后才能决定下一步的处理
  /// 比如打牌的时候，creator等待所有的参与者的回复，才决定是继续发牌还是有人胡牌或者杠牌
  /// Set<int>为等待回复的参与者
  Set<int> outstandingParticipants = {};

  /// 刚出牌的参与者
  int? discardParticipant;

  Tile? discardTile;

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
      ...fullPile.tiles,
      ...fullPile.tiles,
      ...fullPile.tiles,
      ...fullPile.tiles
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

  addOutstandingParticipants(List<int> participants) {
    outstandingParticipants.addAll(participants);
  }

  /// 消解并检查等待的事件，如果全部消解则返回true，否则，返回false
  bool checkOutstandingParticipant(int index) {
    if (outstandingParticipants.contains(index)) {
      outstandingParticipants.remove(index);
    }
    return outstandingParticipants.isEmpty;
  }

  bool get isSeaTake {
    return stockPile!.tiles.length < 5;
  }

  /// 下面所有的事件命令函数，非_打头的是发起的参与者的直接调用的执行函数
  /// _打头的是通过消息接收到的其他参与者发起的事件

  /// creator发牌，只能是creator才能执行，把牌发给打牌人discard的下一家或者banker
  Future<Tile?> deal() async {
    int owner =
        discardParticipant != null ? room.next(discardParticipant!) : banker;
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
        'deal tile ${tile.toString()}, leave ${stockPile!.tiles.length} tiles');

    discardParticipant = null;
    discardTile = null;

    RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.deal(owner, tile, dealTileType.index);

    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i == room.creator) {
        continue;
      }
      if (i == owner) {
        RoomEvent tileRoomEvent = RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.deal,
            tile: tile,
            pos: dealTileType.index);
        await _sendChatMessage(tileRoomEvent, room.creator, [owner]);
      } else {
        RoomEvent unknownRoomEvent = RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.deal,
            tile: unknownTile,
            pos: dealTileType.index);
        await _sendChatMessage(unknownRoomEvent, room.creator, [i]);
      }
    }

    return tile;
  }

  /// 收到发的牌tile的消息
  Tile? _deal(int owner, Tile tile, int dealTileTypeIndex) {
    logger.w('chat message: receive $owner deal tile ${tile.toString()}');
    discardParticipant = null;
    discardTile = null;

    RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.deal(owner, tile, dealTileTypeIndex);

    return tile;
  }

  /// 主动打牌，owner表示打牌的参与者，receiver代表接收到事件的参与者
  /// 返回值是true，表示打的牌没有需要等待的处理，可以发牌
  /// 否则，表示有需要等待的处理
  Future<bool> discard(int owner, Tile tile) async {
    logger.w('$owner discard tile ${tile.toString()}');

    /// 打牌的参与者执行事件处理
    discardParticipant = owner;
    discardTile = tile;

    final RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.discard(owner, tile);

    int sender = owner;
    List<int> receivers = [];
    RoomEvent discardRoomEvent = RoomEvent(room.name,
        roundId: id, owner: owner, action: RoomEventAction.discard, tile: tile);
    bool pass = true;
    outstandingParticipants.clear();
    for (int i = 0; i < roundParticipants.length; ++i) {
      receivers.add(i);
      if (room.creator != i && owner == room.creator) {
        Map<MahjongAction, Set<int>>? outstandingActions =
            roundParticipants[i].check(tile: tile);
        if (outstandingActions.isNotEmpty) {
          pass = false;
          addOutstandingParticipants([i]);
        }
      }
    }
    if (owner == room.creator && pass) {
      deal();
    }

    /// 没有receiver，不是消息事件，creator发送事件消息给其他参与者，或者发送消息事件给creator
    /// 有receiver，是消息事件，receiver是creator发送事件消息给其他参与者，否则不发送消息
    await _sendChatMessage(discardRoomEvent, sender, receivers);

    return pass;
  }

  /// 收到owner打牌的消息
  bool _discard(int owner, Tile tile, int receiver) {
    logger.w('chat message: $owner discard tile ${tile.toString()}');

    /// 打牌的参与者执行事件处理
    discardParticipant = owner;
    discardTile = tile;

    final RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.discard(owner, tile);
    roundParticipants[receiver].check(tile: tile);

    bool pass = true;

    /// receiver不为空，事件是消息触发
    if (receiver == room.creator) {
      outstandingParticipants.clear();

      /// 事件消息的接收者是creator，检查，发消息给其他参与者，2个消息，等待2个事件
      for (int i = 0; i < roundParticipants.length; ++i) {
        if (owner != i) {
          Map<MahjongAction, Set<int>>? outstandingActions =
              roundParticipants[i].check(tile: tile);
          if (outstandingActions.isNotEmpty) {
            pass = false;
            addOutstandingParticipants([i]);
          }
        }
      }
      if (pass) {
        deal();
      }
    }

    return pass;
  }

  Future<bool> pass(int owner) async {
    logger.w('$owner pass');
    final RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.pass(owner);

    if (owner == room.creator) {
      bool pass = checkOutstandingParticipant(owner);
      if (pass) {
        deal();
      }
    }
    RoomEvent passRoomEvent = RoomEvent(room.name,
        roundId: id, owner: owner, action: RoomEventAction.pass);
    await _sendChatMessage(passRoomEvent, owner, [room.creator]);

    return true;
  }

  /// 收到owner pass的消息
  bool _pass(int owner, int receiver) {
    logger.w('chat message: $owner pass');
    final RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.pass(owner);

    if (receiver == room.creator) {
      bool pass = checkOutstandingParticipant(owner);
      if (pass) {
        deal();
      }
    }

    return true;
  }

  /// 某个参与者碰打出的牌
  Future<Tile?> touch(int owner,
      {int? pos, int? src, Tile? discardTile}) async {
    if (this.discardTile == null) {
      logger.e('$owner touch, but discardTile is null');

      return null;
    }
    if (discardParticipant == null) {
      logger.e('$owner touch, but discardParticipant is null');

      return null;
    }
    if (discardTile == null) {
      discardTile = this.discardTile;
    } else {
      if (discardTile != this.discardTile) {
        logger.e('$owner touch, but discardTile:$discardTile is not equal');

        return null;
      }
    }
    if (src == null) {
      src = discardParticipant;
    } else {
      if (discardParticipant != src) {
        logger.e('$owner touch, but discardParticipant is not equal src:$src');

        return null;
      }
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    discardTile = roundParticipant.touch(owner, pos!, src!, discardTile!);
    if (discardTile == null) {
      return null;
    }

    List<Tile> tiles = roundParticipants[src].wastePile.tiles;
    if (tiles.isNotEmpty && discardTile == tiles.last) {
      tiles.removeLast();
    }

    discardParticipant = null;
    this.discardTile = null;

    RoomEvent touchRoomEvent = RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.touch,
        tile: discardTile,
        pos: pos,
        src: src);
    for (int i = 0; i < roundParticipants.length; ++i) {
      await _sendChatMessage(touchRoomEvent, owner, [i]);
    }

    return discardTile;
  }

  Tile? _touch(int owner, int pos, int src, Tile discardTile, int receiver) {
    logger.w('chat message: $owner touch pos:$pos src:$src tile:$discardTile');
    if (this.discardTile == null) {
      logger.e('$owner touch, but discardTile is null');

      return null;
    }
    if (discardParticipant == null) {
      logger.e('$owner touch, but discardParticipant is null');

      return null;
    }
    if (discardTile != this.discardTile) {
      logger.e('$owner touch, but discardTile:$discardTile is not equal');

      return null;
    }
    if (discardParticipant != src) {
      logger.e('$owner touch, but discardParticipant is not equal src:$src');

      return null;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    Tile? tile = roundParticipant.touch(owner, pos, src, discardTile);
    if (tile == null) {
      return null;
    }
    List<Tile> tiles = roundParticipants[src].wastePile.tiles;
    if (tiles.isNotEmpty && discardTile == tiles.last) {
      tiles.removeLast();
    }

    discardParticipant = null;
    this.discardTile = null;

    return tile;
  }

  int get barCount {
    int c = 0;
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      List<Set<MahjongActionValue>> counts =
          roundParticipant.earnedActions.values.toList();
      for (var count in counts) {
        c += count.length;
      }
    }

    return c;
  }

  /// 某个参与者明杠牌，pos表示可杠的手牌的位置
  /// 明杠牌，分三种情况，打牌杠牌，摸牌杠牌和手牌杠牌
  /// 打牌杠牌:返回值为杠的牌，为空表示未成功
  /// 摸牌杠牌和手牌杠牌:pos为-1，表示是摸牌可杠，否则表示手牌可杠的位置
  Future<Tile?> bar(int owner, int pos) async {
    RoundParticipant roundParticipant = roundParticipants[owner];
    Tile? tile;
    int? src;
    if (pos == -1) {
      tile = roundParticipant.drawBar(owner, pos);
      if (tile != null) {
        src = owner;
      }
    } else if (pos > -1 && discardParticipant != null) {
      tile = roundParticipant.discardBar(
          owner, pos, discardTile!, discardParticipant!);
      if (tile != null) {
        src = discardParticipant;
        List<Tile> tiles = roundParticipants[src!].wastePile.tiles;
        if (tiles.isNotEmpty && discardTile == tiles.last) {
          tiles.removeLast();
        }
        discardParticipant = null;
        discardTile = null;
      }
    }
    if (tile == null) {
      return null;
    }

    RoomEvent barRoomEvent = RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.bar,
        tile: tile,
        pos: pos,
        src: src);
    int sender = owner;
    List<int> receivers = [];
    bool pass = true;
    for (int i = 0; i < roundParticipants.length; ++i) {
      receivers.add(i);
      if (owner == room.creator && room.creator != i) {
        WinType? winType = roundParticipants[i].checkWin(i, tile);
        if (winType != null) {
          pass = false;
          addOutstandingParticipants([i]);
        }
      }
    }
    await _sendChatMessage(barRoomEvent, sender, receivers);
    if (owner == room.creator && pass) {
      barDeal(owner);
    }

    return tile;
  }

  /// 收到owner杠牌的消息
  Tile? _bar(int owner, int pos, Tile tile, int src, int receiver) {
    logger.w('chat message: $owner bar pos:$pos');
    RoundParticipant roundParticipant = roundParticipants[owner];
    if (pos == -1) {
      roundParticipant.drawBar(owner, pos);
    } else if (pos > -1) {
      Tile? discardBarTile = roundParticipant.discardBar(owner, pos, tile, src);
      if (discardBarTile != null) {
        List<Tile> tiles = roundParticipants[src].wastePile.tiles;
        if (tiles.isNotEmpty && tile == tiles.last) {
          tiles.removeLast();
        }
        discardParticipant = null;
        discardTile = null;
      }
    }
    roundParticipants[receiver].checkWin(receiver, tile);

    bool pass = true;

    /// receiver不为空，事件是消息触发
    if (receiver == room.creator) {
      /// 事件消息的接收者是creator，检查，发消息给其他参与者，2个消息，等待2个事件
      for (int i = 0; i < roundParticipants.length; ++i) {
        if (owner != i) {
          WinType? winType = roundParticipants[i].checkWin(i, tile);
          if (winType != null) {
            pass = false;
            addOutstandingParticipants([i]);
          }
        }
      }
      if (pass) {
        barDeal(owner);
      }
    }

    return tile;
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

    logger.w(
        'barDeal tile ${tile.toString()}, leave ${stockPile!.tiles.length} tiles');

    discardParticipant = null;
    discardTile = null;

    RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.deal(owner, tile, DealTileType.bar.index);

    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i == room.creator) {
        continue;
      }
      if (i == owner) {
        RoomEvent tileRoomEvent = RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.deal,
            tile: tile,
            pos: DealTileType.bar.index);
        await _sendChatMessage(tileRoomEvent, room.creator, [owner]);
      } else {
        RoomEvent unknownRoomEvent = RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.deal,
            tile: unknownTile,
            pos: DealTileType.bar.index);
        await _sendChatMessage(unknownRoomEvent, room.creator, [i]);
      }
    }

    return tile;
  }

  /// owner抢src的明杠牌card
  _rob(int owner, int src, Tile tile, {int? receiver}) {}

  /// 某个参与者暗杠，pos表示杠牌的位置
  Future<Tile?> darkBar(int owner, int pos) async {
    RoundParticipant roundParticipant = roundParticipants[owner];
    Tile? tile = roundParticipant.darkBar(owner, pos);
    if (tile == null) {
      return null;
    }
    RoomEvent barRoomEvent = RoomEvent(room.name,
        roundId: id, owner: owner, action: RoomEventAction.darkBar, pos: pos);
    for (int i = 0; i < roundParticipants.length; ++i) {
      await _sendChatMessage(barRoomEvent, owner, [i]);
    }

    if (owner == room.creator) {
      barDeal(owner);
    }

    return tile;
  }

  Tile? _darkBar(int owner, int pos, int receiver) {
    logger.w('chat message: $owner darkBar pos:$pos');
    RoundParticipant roundParticipant = roundParticipants[owner];
    Tile? tile = roundParticipant.darkBar(owner, pos);
    if (receiver == room.creator) {
      barDeal(owner);
    }

    return tile;
  }

  /// 某个参与者吃打出的牌，pos表示吃牌的位置
  /// 暂时不实现这个功能
  Tile? chow(int owner, int pos) {
    if (discardTile == null) {
      return null;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    Tile? tile = roundParticipant.chow(owner, pos, discardTile!);
    if (tile == null) {
      return tile;
    }
    roundParticipants[discardParticipant!].wastePile.tiles.removeLast();
    discardParticipant = null;
    discardTile = null;

    return tile;
  }

  Tile? _chow(int owner, int pos) {
    if (discardTile == null) {
      return null;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    Tile? tile = roundParticipant.chow(owner, pos, discardTile!);
    if (tile == null) {
      return tile;
    }

    roundParticipants[discardParticipant!].wastePile.tiles.removeLast();
    discardParticipant = null;
    discardTile = null;

    return tile;
  }

  bool _score(int owner, int winTypeIndex) {
    WinType? winType = NumberUtil.toEnum(WinType.values, winTypeIndex);
    if (winType == null) {
      return false;
    }
    int? baseScore = room.completeTypeScores[winType];
    if (baseScore == null) {
      return false;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];

    /// 抢杠，owner是胡牌人，robber是被抢人
    if (robber != null && robCard != null) {
      roundParticipant.score.value += baseScore * 3;
      roundParticipants[robber!].score.value -= baseScore * 3;
    } else if (roundParticipant.handPile.drawTileType == DealTileType.bar ||
        roundParticipant.handPile.drawTileType == DealTileType.sea) {
      /// 杠上开花或者海底捞月
      baseScore = baseScore * 2;
      roundParticipant.score.value += baseScore * 3;
    } else if (roundParticipant.handPile.drawTileType == DealTileType.self) {
      /// 自摸
      roundParticipant.score.value += baseScore * 3;
    } else {
      /// 接别人打牌胡
      roundParticipant.score.value += baseScore;
    }
    if (discardParticipant != null) {
      /// 打牌别人胡
      roundParticipants[discardParticipant!].score.value -= baseScore;
    } else {
      if (roundParticipant.packer != null) {
        /// 包
        RoundParticipant pc = roundParticipants[roundParticipant.packer!];
        pc.score.value -= 3 * baseScore;
      } else {
        /// 别人自摸
        for (int i = 0; i < roundParticipants.length; ++i) {
          if (i != owner) {
            RoundParticipant roundParticipant = roundParticipants[i];
            roundParticipant.score.value -= baseScore;
          }
        }
      }
    }

    /// 杠牌的计算
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      for (var entry in roundParticipant.earnedActions.entries) {
        MahjongAction mahjongAction = entry.key;

        /// 暗杠
        if (mahjongAction == MahjongAction.darkBar) {
          Set<MahjongActionValue> mahjongActionValues = entry.value;
          for (var mahjongActionValue in mahjongActionValues) {
            if (mahjongActionValue.bar == mahjongActionValue.discard) {
              if (i == mahjongActionValue.bar) {
                roundParticipant.score.value += 60;
              } else {
                roundParticipant.score.value -= 20;
              }
            }
          }
        }

        /// 明杠
        if (mahjongAction == MahjongAction.bar) {
          Set<MahjongActionValue> mahjongActionValues = entry.value;
          for (var mahjongActionValue in mahjongActionValues) {
            // 自摸杠
            if (mahjongActionValue.bar == mahjongActionValue.discard) {
              if (i == mahjongActionValue.bar) {
                roundParticipant.score.value += 30;
              } else {
                roundParticipant.score.value -= 10;
              }
            } else {
              if (i == mahjongActionValue.bar) {
                roundParticipant.score.value += 30;
              } else if (i == mahjongActionValue.discard) {
                roundParticipant.score.value -= 30;
              }
            }
          }
        }
      }
    }

    return true;
  }

  /// 某个参与者胡牌,pos表示胡牌的类型
  Future<WinType?> win(int owner, int pos) async {
    RoundParticipant roundParticipant = roundParticipants[owner];
    WinType? winType = roundParticipant.win(owner, pos);
    if (winType == null) {
      return null;
    }
    bool? confirm =
        await DialogUtil.confirm(content: 'Do you want win ${winType.name}');
    if (confirm == null || !confirm) {
      return null;
    }
    _score(owner, winType.index);
    RoomEvent winRoomEvent = RoomEvent(room.name,
        roundId: id, owner: owner, pos: pos, action: RoomEventAction.win);
    for (int i = 0; i < roundParticipants.length; ++i) {
      await _sendChatMessage(winRoomEvent, owner, [i]);
    }
    if (owner == room.creator) {
      room.banker = owner;
      room.startRoomEvent(RoomEvent(room.name,
          roundId: id, owner: owner, action: RoomEventAction.round));
    }

    return winType;
  }

  WinType? _win(int owner, int pos, int receiver) {
    RoundParticipant roundParticipant = roundParticipants[owner];
    WinType? winType = roundParticipant.win(owner, pos);
    if (winType == null) {
      return null;
    }
    _score(owner, winType.index);
    if (receiver == room.creator) {
      room.banker = owner;
      room.startRoomEvent(RoomEvent(room.name,
          roundId: id, owner: owner, action: RoomEventAction.round));
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
      if (roomEvent.sender != roomEvent.receiver) {
        ChatMessage chatMessage = await chatMessageService.buildChatMessage(
            receiverPeerId: roundParticipant.participant.peerId,
            subMessageType: ChatMessageSubType.mahjong,
            content: roomEvent);
        if (roundParticipant.participant.robot ||
            roundParticipants[sender].participant.robot) {
          logger.w('round:$id has robot sent event:${roomEvent.toString()}');
          roomPool.onRoomEvent(chatMessage);
        } else {
          logger.w('round:$id has no robot sent event:${roomEvent.toString()}');
          roomPool.send(chatMessage);
        }
      }
    }
  }

  dynamic startRoomEvent(RoomEvent roomEvent) async {
    // logger.w('round:$id has received event:${roomEvent.toString()}');
    dynamic returnValue;
    RoomEventAction? action = roomEvent.action;
    switch (action) {
      case RoomEventAction.deal:
        returnValue = deal();
      case RoomEventAction.discard:
        returnValue = discard(roomEvent.owner, roomEvent.tile!);
      case RoomEventAction.bar:
        returnValue = bar(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.touch:
        returnValue = touch(roomEvent.owner,
            pos: roomEvent.pos!,
            src: roomEvent.src!,
            discardTile: roomEvent.tile!);
      case RoomEventAction.darkBar:
        returnValue = darkBar(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.chow:
        returnValue = chow(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.pass:
        returnValue = pass(roomEvent.owner);
      case RoomEventAction.win:
        returnValue = win(roomEvent.owner, roomEvent.pos!);
      default:
        break;
    }

    if (roomEvent.action == RoomEventAction.discard) {
      mahjongFlameGame.reloadNext();
    }
    mahjongFlameGame.reloadSelf();

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
  dynamic onRoomEvent(RoomEvent roomEvent) async {
    // logger.w('round:$id has received event:${roomEvent.toString()}');
    dynamic returnValue;
    RoomEventAction? action = roomEvent.action;
    switch (action) {
      case RoomEventAction.deal:
        returnValue = _deal(roomEvent.owner, roomEvent.tile!, roomEvent.pos!);
      case RoomEventAction.discard:
        returnValue =
            _discard(roomEvent.owner, roomEvent.tile!, roomEvent.receiver!);
      case RoomEventAction.bar:
        returnValue = _bar(roomEvent.owner, roomEvent.pos!, roomEvent.tile!,
            roomEvent.src!, roomEvent.receiver!);
      case RoomEventAction.barDeal:
        returnValue = barDeal(roomEvent.owner);
      case RoomEventAction.touch:
        returnValue = _touch(roomEvent.owner, roomEvent.pos!, roomEvent.src!,
            roomEvent.tile!, roomEvent.receiver!);
      case RoomEventAction.darkBar:
        returnValue =
            _darkBar(roomEvent.owner, roomEvent.pos!, roomEvent.receiver!);
      case RoomEventAction.chow:
        returnValue = _chow(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.rob:
        returnValue = _rob(roomEvent.owner, roomEvent.src!, roomEvent.tile!,
            receiver: roomEvent.receiver);
      case RoomEventAction.score:
        returnValue = _score(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.pass:
        returnValue = _pass(roomEvent.owner, roomEvent.receiver!);
      case RoomEventAction.win:
        returnValue =
            _win(roomEvent.owner, roomEvent.pos!, roomEvent.receiver!);
      default:
        break;
    }

    if (roomEvent.action == RoomEventAction.discard) {
      mahjongFlameGame.reloadNext();
    }
    mahjongFlameGame.reloadSelf();

    return returnValue;
  }
}
