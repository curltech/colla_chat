import 'dart:math';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart';
import 'package:colla_chat/pages/game/mahjong/base/full_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/hand_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/outstanding_action.dart';
import 'package:colla_chat/pages/game/mahjong/base/participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_pool.dart';
import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/stock_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
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
  /// key为事件的编号，Set<int>为等待回复的参与者
  Map<String, Set<int>> outstandingRoomEvents = {};

  /// 刚出牌的参与者
  int? discard;

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

  addOutstandingRoomEvent(String eventId, List<int> vs) {
    Set<int>? values = outstandingRoomEvents[eventId];
    if (values == null) {
      values = {};
      outstandingRoomEvents[eventId] = values;
    }
    values.addAll(vs);
  }

  /// 消解并检查等待的事件，如果全部消解则返回true，否则，返回false
  bool checkOutstandingRoomEvent(String eventId, int v) {
    Set<int>? values = outstandingRoomEvents[eventId];
    if (values != null) {
      if (values.contains(v)) {
        values.remove(v);
      }
      if (values.isEmpty) {
        outstandingRoomEvents.remove(eventId);
      }

      return !outstandingRoomEvents.containsKey(eventId);
    }

    return true;
  }

  bool get isSeaTake {
    return stockPile!.tiles.length < 5;
  }

  /// creator发牌，只能是creator才能执行，把牌发给owner
  Tile? deal(int owner) {
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

    return _deal(owner, tile, dealTileType.index);
  }

  /// 收到发的牌tile
  Tile? _deal(int owner, Tile tile, int dealTileTypeIndex, {int? receiver}) {
    logger.w('$receiver receive $owner deal tile ${tile.toString()}');
    discard = null;
    discardTile = null;
    int executor = (receiver ?? owner);
    RoundParticipant roundParticipant = roundParticipants[executor];

    roundParticipant.deal(owner, tile, dealTileTypeIndex);

    if (receiver == null) {
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
              pos: dealTileTypeIndex);
          _sendChatMessage(tileRoomEvent, room.creator, [owner]);
        } else {
          RoomEvent unknownRoomEvent = RoomEvent(room.name,
              roundId: id,
              owner: owner,
              action: RoomEventAction.deal,
              tile: unknownTile,
              pos: dealTileTypeIndex);
          _sendChatMessage(unknownRoomEvent, room.creator, [i]);
        }
      }
    }

    return tile;
  }

  /// 打牌，每个参与者都要执行一次
  /// owner表示打牌的参与者，receiver代表接收到事件的参与者
  /// 返回值是true，表示打的牌没有需要等待的处理，可以发牌
  /// 否则，表示有需要等待的处理
  bool _discard(int owner, Tile tile, {int? receiver}) {
    logger.w('$owner discard tile ${tile.toString()} to $receiver}');

    /// 打牌的参与者执行事件处理
    discard = owner;
    discardTile = tile;

    RoundParticipant roundParticipant;
    int? sender;
    List<int>? receivers;
    RoomEvent discardRoomEvent = RoomEvent(room.name,
        roundId: id, owner: owner, action: RoomEventAction.discard, tile: tile);
    bool pass = true;
    if (receiver == null) {
      /// receiver为空，事件初次触发
      if (owner == room.creator) {
        /// 事件的触发者是creator，检查，发消息给其他参与者，3个消息，等待3个事件
        roundParticipant = roundParticipants[owner];
        sender = room.creator;
        receivers = [];
        for (int i = 0; i < roundParticipants.length; ++i) {
          if (room.creator != i) {
            receivers.add(i);
            Map<OutstandingAction, Set<int>>? outstandingActions =
                roundParticipants[i].check(tile: tile);
            if (outstandingActions.isNotEmpty) {
              pass = false;
              addOutstandingRoomEvent(discardRoomEvent.id, [i]);
            }
          }
        }
        if (pass) {
          deal(room.next(owner));
        }
      } else {
        /// 事件的触发者不是creator，检查，发消息给creator，1个消息，不等待事件
        roundParticipant = roundParticipants[owner];
        sender = owner;
        receivers = [room.creator];
      }
    } else {
      /// receiver不为空，事件是消息触发
      if (receiver == room.creator) {
        /// 事件消息的接收者是creator，检查，发消息给其他参与者，2个消息，等待2个事件
        roundParticipant = roundParticipants[receiver];
        sender = room.creator;
        receivers = [];

        for (int i = 0; i < roundParticipants.length; ++i) {
          if (owner != i) {
            if (room.creator != i) {
              receivers.add(i);
            }
            Map<OutstandingAction, Set<int>>? outstandingActions =
                roundParticipants[i].check(tile: tile);
            if (outstandingActions.isNotEmpty) {
              pass = false;
              addOutstandingRoomEvent(discardRoomEvent.id, [i]);
            }
          }
        }
        if (pass) {
          deal(room.next(owner));
        }
      } else {
        /// 事件消息的接收者不是creator，检查，不发消息
        roundParticipant = roundParticipants[receiver];
      }
    }

    roundParticipant.discard(owner, tile);

    /// 没有receiver，不是消息事件，creator发送事件消息给其他参与者，或者发送消息事件给creator
    /// 有receiver，是消息事件，receiver是creator发送事件消息给其他参与者，否则不发送消息
    if (sender != null) {
      _sendChatMessage(discardRoomEvent, sender, receivers!);
    }

    return pass;
  }

  /// 杠牌发牌
  Tile? _barDeal(int owner, {int? receiver}) {
    if (stockPile == null || stockPile!.tiles.isEmpty) {
      return null;
    }
    int mod = barCount % 2;
    Tile tile;
    if (mod == 0 && stockPile!.tiles.length > 1) {
      tile = stockPile!.tiles.removeAt(stockPile!.tiles.length - 2);
    } else {
      tile = stockPile!.tiles.removeLast();
    }
    discard = null;
    discardTile = null;
    RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.deal(owner, tile, DealTileType.bar.index);
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i != owner) {
        roundParticipant = roundParticipants[i];
        roundParticipant.deal(owner, tile, DealTileType.bar.index);
      }
    }

    return tile;
  }

  /// 某个参与者过，没有采取任何行为
  bool _pass(int owner, {int? receiver}) {
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[owner];
      if (roundParticipant.outstandingActions
          .containsKey(OutstandingAction.win)) {
        // discard = owner;
        // discardTile = playCard;
      }
    }
    robber = null;
    robCard = null;
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roundParticipant.pass(owner);
    }

    bool pass = true;
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      if (roundParticipant.outstandingActions.isNotEmpty) {
        pass = false;
        break;
      }
    }
    if (pass) {
      onRoomEvent(RoomEvent(room.name,
          roundId: id, owner: room.next(owner), action: RoomEventAction.deal));
    }

    return true;
  }

  /// 某个参与者碰打出的牌
  bool _touch(int owner, int pos, int src, Tile discardTile, {int? receiver}) {
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roundParticipant.touch(owner, pos, src, discardTile);
    }
    if (roundParticipants[owner].handPile.touchPiles.length == 4) {
      roundParticipants[owner].packer = discard;
    }
    if (discard != null) {
      List<Tile> tiles = roundParticipants[discard!].wastePile.tiles;
      if (tiles.isNotEmpty) {
        tiles.removeLast();
      }
    }
    discard = null;
    this.discardTile = null;

    return true;
  }

  int get barCount {
    int c = 0;
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      List<Set<int>> counts = roundParticipant.earnedActions.values.toList();
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
  String? _bar(int owner, int pos, {int? receiver}) {
    /// 检查抢杠
    bool canRob = false;
    if (discardTile != null) {
      Map<int, WinType>? winTypes =
          _checkWin(owner, discardTile!, receiver: receiver);
      if (winTypes != null) {
        canRob = true;
        robber = owner;
        robCard = discardTile;
      }
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roundParticipant.bar(owner, pos, discard: discard, tile: discardTile);
    }
    if (discard != null) {
      roundParticipants[discard!].wastePile.tiles.removeLast();
      if (roundParticipants[owner].handPile.touchPiles.length == 4) {
        roundParticipants[owner].packer = discard;
      }
    }
    discard = null;
    discardTile = null;
    if (canRob) {
      return null;
    }

    _barDeal(owner);

    return null;
  }

  Map<int, WinType>? _checkWin(int owner, Tile tile, {int? receiver}) {
    Map<int, WinType>? winTypes;
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        WinType? winType = roundParticipant.checkWin(owner, tile);
        if (winType != null) {
          winTypes ??= {};
          winTypes[i] = winType;
        }
      }
    }

    return winTypes;
  }

  /// owner抢src的明杠牌card
  _rob(int owner, int src, Tile tile, {int? receiver}) {}

  /// 某个参与者暗杠，pos表示杠牌的位置
  Tile? _darkBar(int owner, int pos, {int? receiver}) {
    RoundParticipant roundParticipant = roundParticipants[owner];
    Tile? tile = roundParticipant.darkBar(owner, pos);
    if (tile == null) {
      return null;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.darkBar(owner, pos);
      }
    }
    _barDeal(owner);

    return tile;
  }

  /// 某个参与者吃打出的牌，pos表示吃牌的位置
  Tile? _chow(int owner, int pos, {int? receiver}) {
    if (discardTile == null) {
      return null;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    Tile? tile = roundParticipant.chow(owner, pos, discardTile!);
    if (tile == null) {
      return tile;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.darkBar(owner, pos);
      }
    }
    roundParticipants[discard!].wastePile.tiles.removeLast();
    discard = null;
    discardTile = null;

    return tile;
  }

  bool _score(int owner, int winTypeIndex, {int? receiver}) {
    WinType? winType = NumberUtil.toEnum(WinType.values, winTypeIndex);
    if (winType == null) {
      return false;
    }
    int? baseScore = room.completeTypeScores[winType];
    if (baseScore == null) {
      return false;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    if (robber != null && robCard != null) {
      roundParticipant.score.value += baseScore * 3;
      roundParticipants[robber!].score.value -= baseScore * 3;
    } else if (roundParticipant.handPile.drawTileType == DealTileType.bar ||
        roundParticipant.handPile.drawTileType == DealTileType.sea) {
      baseScore = baseScore * 2;
      roundParticipant.score.value += baseScore * 3;
    } else if (roundParticipant.handPile.drawTileType == DealTileType.self) {
      roundParticipant.score.value += baseScore * 3;
    } else {
      roundParticipant.score.value += baseScore;
    }
    if (discard != null) {
      roundParticipants[discard!].score.value -= baseScore;
    } else {
      if (roundParticipant.packer != null) {
        RoundParticipant pc = roundParticipants[roundParticipant.packer!];
        pc.score.value -= 3 * baseScore;
      } else {
        for (int i = 0; i < roundParticipants.length; ++i) {
          if (i != owner) {
            RoundParticipant roundParticipant = roundParticipants[i];
            roundParticipant.score.value -= baseScore;
          }
        }
      }
    }

    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      for (var entry in roundParticipant.earnedActions.entries) {
        OutstandingAction outstandingAction = entry.key;
        if (outstandingAction == OutstandingAction.darkBar) {}
        if (outstandingAction == OutstandingAction.bar) {
          Set<int> participants = entry.value;
          for (var participant in participants) {
            // 自摸杠
            if (i == participant) {
              roundParticipant.score.value += 10;
            } else {}
          }
        }
      }
    }

    return true;
  }

  /// 某个参与者胡牌,pos表示胡牌的类型
  WinType? _win(int owner, int pos, {int? receiver}) {
    RoundParticipant roundParticipant = roundParticipants[owner];
    WinType? winType = roundParticipant.win(owner, pos);
    if (winType == null) {
      return null;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.win(owner, pos);
      }
    }
    room.banker = owner;

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
        if (roundParticipant.participant.robot) {
          logger.w('round:$id has robot sent event:${roomEvent.toString()}');
          roomPool.onRoomEvent(chatMessage);
        } else {
          logger.w('round:$id has no robot sent event:${roomEvent.toString()}');
          roomPool.send(chatMessage);
        }
      }
    }
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
        returnValue = _deal(roomEvent.owner, roomEvent.tile!, roomEvent.pos!,
            receiver: roomEvent.receiver);
      case RoomEventAction.discard:
        returnValue = _discard(roomEvent.owner, roomEvent.tile!,
            receiver: roomEvent.receiver);
      case RoomEventAction.bar:
        returnValue =
            _bar(roomEvent.owner, roomEvent.pos!, receiver: roomEvent.receiver);
      case RoomEventAction.barDeal:
        returnValue = _barDeal(roomEvent.owner, receiver: roomEvent.receiver);
      case RoomEventAction.touch:
        returnValue = _touch(
            roomEvent.owner, roomEvent.pos!, roomEvent.src!, roomEvent.tile!,
            receiver: roomEvent.receiver);
      case RoomEventAction.darkBar:
        returnValue = _darkBar(roomEvent.owner, roomEvent.pos!,
            receiver: roomEvent.receiver);
      case RoomEventAction.chow:
        returnValue = _chow(roomEvent.owner, roomEvent.pos!,
            receiver: roomEvent.receiver);
      case RoomEventAction.rob:
        returnValue = _rob(roomEvent.owner, roomEvent.src!, roomEvent.tile!,
            receiver: roomEvent.receiver);
      case RoomEventAction.score:
        returnValue = _score(roomEvent.owner, roomEvent.pos!,
            receiver: roomEvent.receiver);
      case RoomEventAction.pass:
        returnValue = _pass(roomEvent.owner, receiver: roomEvent.receiver);
      case RoomEventAction.win:
        returnValue =
            _win(roomEvent.owner, roomEvent.pos!, receiver: roomEvent.receiver);
      default:
        break;
    }

    if (roomEvent.action == RoomEventAction.discard) {
      roomController.mahjongFlameGame.reloadNext();
    }
    roomController.mahjongFlameGame.reloadSelf();

    return returnValue;
  }
}
