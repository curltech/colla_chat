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
enum DealCardType { self, bar, sea }

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

  /// 最新的发牌的参与者，就是banker把牌发给taker
  late int dealer;

  /// 当参与者打牌或者明杠的时候，creator需要等待其他参与者的回复事件
  /// creator只有等到其他参与者的回复事件后才能决定下一步的处理
  /// 比如打牌的时候，creator等待所有的参与者的回复，才决定是继续发牌还是有人胡牌或者杠牌
  /// key为事件的编号，List<int>为等待回复的参与者
  Map<String, Set<int>> outstandingRoomEvents = {};

  /// 刚出牌的参与者
  int? discard;

  Tile? discardTile;

  /// 同圈放弃的胡牌
  // int? discard;
  // Tile? discardTile;

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
    List<Tile> stockCards = [
      ...fullPile.tiles,
      ...fullPile.tiles,
      ...fullPile.tiles,
      ...fullPile.tiles
    ];
    stockPile = StockPile();
    Random random = Random.secure();

    /// 牌的总数是136
    for (int i = 0; i < 136; ++i) {
      int pos = random.nextInt(stockCards.length);
      Tile card = stockCards.removeAt(pos);

      /// 每个参与者发13张牌
      if (i < 52) {
        int reminder = (i + banker) % 4;
        roundParticipants[reminder].handPile.tiles.add(card);
      } else {
        stockPile!.tiles.add(card);
      }
    }

    /// 手牌排序
    for (var roundParticipant in roundParticipants) {
      roundParticipant.handPile.sort();
    }
  }

  /// stockPile不为空，则是creator
  bool get isCreator {
    return stockPile != null;
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
  RoomEvent? deal(int owner, {int? receiver}) {
    if (stockPile == null) {
      logger.e('owner:$owner take card failure, not creator');
      return null;
    }
    Tile? first = stockPile!.tiles.firstOrNull;
    if (first == null) {
      logger.e('owner:$owner take card failure, stockPile is empty');
      return null;
    }

    DealCardType dealCardType = DealCardType.self;
    if (isSeaTake) {
      dealCardType = DealCardType.sea;
    }
    Tile tile = stockPile!.tiles.removeLast();
    logger.w(
        'deal card ${tile.toString()}, leave ${stockPile!.tiles.length} cards');

    return RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.deal,
        tile: tile,
        pos: dealCardType.index);
  }

  /// 收到发的牌tile
  Tile? _deal(int owner, Tile tile, int dealTileTypeIndex, {int? receiver}) {
    discard = null;
    discardTile = null;
    int executor = (receiver ?? owner);
    RoundParticipant roundParticipant = roundParticipants[executor];
    bool robot = roundParticipant.participant.robot;
    if (!robot) {
      RoomEvent roomEvent = RoomEvent(room.name,
          roundId: id,
          owner: owner,
          action: RoomEventAction.deal,
          tile: tile,
          pos: dealTileTypeIndex);
      roundParticipant.onRoomEvent(roomEvent);

      _sendChatMessage(roomEvent, room.creator, [1, 2, 3]);
    }

    return tile;
  }

  /// 打牌，每个参与者都要执行一次
  /// owner表示打牌的参与者，receiver代表接收到事件的参与者
  Map<OutstandingAction, Set<int>>? _discard(int owner, Tile tile,
      {int? receiver}) {
    /// 打牌的参与者执行事件处理
    discard = owner;
    discardTile = tile;

    RoundParticipant roundParticipant;
    int? sender;
    List<int>? receivers;
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
          }
        }
      } else {
        /// 事件的触发者不是creator，检查，发消息给creator，1个消息，不等待事件
        roundParticipant = roundParticipants[owner];
        sender = owner;
        receivers = [room.creator];
      }
    } else {
      /// receiver不为空，事件是消息触发
      if (owner == room.creator) {
        /// 事件消息的接收者是creator，检查，发消息给其他参与者，2个消息，等待2个事件
        roundParticipant = roundParticipants[receiver];
        sender = room.creator;
        receivers = [];
        for (int i = 0; i < roundParticipants.length; ++i) {
          if (room.creator != i || owner != i) {
            receivers.add(i);
          }
        }
      } else {
        /// 事件消息的接收者不是creator，检查，不发消息
        roundParticipant = roundParticipants[receiver];
      }
    }
    RoomEvent discardRoomEvent = RoomEvent(room.name,
        roundId: id, owner: owner, action: RoomEventAction.discard, tile: tile);
    RoomEvent checkRoomEvent = RoomEvent(room.name,
        roundId: id, owner: owner, action: RoomEventAction.check, tile: tile);
    bool robot = roundParticipant.participant.robot;
    if (!robot) {
      roundParticipant.onRoomEvent(discardRoomEvent);
    }
    Map<OutstandingAction, Set<int>>? outstandingActions =
        roundParticipant.onRoomEvent(checkRoomEvent);

    /// 没有receiver，不是消息事件，creator发送事件消息给其他参与者，或者发送消息事件给creator
    /// 有receiver，是消息事件，receiver是creator发送事件消息给其他参与者，否则不发送消息
    if (sender != null) {
      _sendChatMessage(discardRoomEvent, sender, receivers!);
    }

    return outstandingActions;
  }

  /// 杠牌发牌
  Tile? _barTake(int owner, {int? receiver}) {
    if (stockPile == null || stockPile!.tiles.isEmpty) {
      return null;
    }
    int mod = barCount % 2;
    Tile card;
    if (mod == 0 && stockPile!.tiles.length > 1) {
      card = stockPile!.tiles.removeAt(stockPile!.tiles.length - 2);
    } else {
      card = stockPile!.tiles.removeLast();
    }
    discard = null;
    discardTile = null;
    RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.onRoomEvent(RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.barTake,
        tile: card,
        pos: DealCardType.bar.index));
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i != owner) {
        roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.deal,
            tile: card,
            pos: DealCardType.bar.index));
      }
    }

    return card;
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
      roundParticipant.onRoomEvent(RoomEvent(room.name,
          roundId: id, owner: owner, action: RoomEventAction.pass));
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
  bool _touch(int owner, int pos, int src, Tile sendCard, {int? receiver}) {
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roundParticipant.onRoomEvent(RoomEvent(room.name,
          roundId: id,
          owner: owner,
          action: RoomEventAction.touch,
          tile: sendCard,
          src: src,
          pos: pos));
    }
    if (roundParticipants[owner].handPile.touchPiles.length == 4) {
      roundParticipants[owner].packer = discard;
    }
    if (discard != null) {
      List<Tile> cards = roundParticipants[discard!].wastePile.tiles;
      if (cards.isNotEmpty) {
        cards.removeLast();
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
      Map<int, WinType>? completeTypes =
          _checkComplete(owner, discardTile!, receiver: receiver);
      if (completeTypes != null) {
        canRob = true;
        robber = owner;
        robCard = discardTile;
      }
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roundParticipant.onRoomEvent(RoomEvent(room.name,
          roundId: id,
          owner: owner,
          action: RoomEventAction.bar,
          src: discard,
          tile: discardTile,
          pos: pos));
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

    _barTake(owner);

    return null;
  }

  Map<int, WinType>? _checkComplete(int owner, Tile card, {int? receiver}) {
    Map<int, WinType>? completeTypes;
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        WinType? completeType = roundParticipant.onRoomEvent(RoomEvent(
            room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.checkWin,
            tile: card));
        if (completeType != null) {
          completeTypes ??= {};
          completeTypes[i] = completeType;
        }
      }
    }

    return completeTypes;
  }

  /// owner抢src的明杠牌card
  _rob(int owner, int src, Tile card, {int? receiver}) {}

  /// 某个参与者暗杠，pos表示杠牌的位置
  Tile? _darkBar(int owner, int pos, {int? receiver}) {
    RoundParticipant roundParticipant = roundParticipants[owner];
    Tile? card = roundParticipant.onRoomEvent(RoomEvent(room.name,
        roundId: id, owner: owner, action: RoomEventAction.darkBar, pos: pos));
    if (card == null) {
      return null;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.darkBar,
            pos: pos));
      }
    }
    _barTake(owner);

    return card;
  }

  /// 某个参与者吃打出的牌，pos表示吃牌的位置
  Tile? _chow(int owner, int pos, {int? receiver}) {
    if (discardTile == null) {
      return null;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    Tile? card = roundParticipant.onRoomEvent(RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.chow,
        pos: pos,
        tile: discardTile));
    if (card == null) {
      return card;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.darkBar,
            pos: pos));
      }
    }
    roundParticipants[discard!].wastePile.tiles.removeLast();
    discard = null;
    discardTile = null;

    return card;
  }

  bool _score(int owner, int completeTypeIndex, {int? receiver}) {
    WinType? completeType =
        NumberUtil.toEnum(WinType.values, completeTypeIndex);
    if (completeType == null) {
      return false;
    }
    int? baseScore = room.completeTypeScores[completeType];
    if (baseScore == null) {
      return false;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    if (robber != null && robCard != null) {
      roundParticipant.score.value += baseScore * 3;
      roundParticipants[robber!].score.value -= baseScore * 3;
    } else if (roundParticipant.handPile.drawTileType == DealCardType.bar ||
        roundParticipant.handPile.drawTileType == DealCardType.sea) {
      baseScore = baseScore * 2;
      roundParticipant.score.value += baseScore * 3;
    } else if (roundParticipant.handPile.drawTileType == DealCardType.self) {
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
    WinType? completeType = roundParticipant.onRoomEvent(RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.win,
        pos: pos,
        tile: discardTile));
    if (completeType == null) {
      return null;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.win,
            pos: pos,
            tile: discardTile));
      }
    }
    room.banker = owner;

    return completeType;
  }

  /// 作为creator，分发事件消息给其他参与者，不包括事件的原始发送者
  /// 否则，发送消息给creator
  _sendChatMessage(RoomEvent roomEvent, int sender, List<int> receivers) async {
    for (int i = 0; i < receivers.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roomEvent.sender = sender;
      roomEvent.receiver = i;
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
    logger.w('round:$id has received event:${roomEvent.toString()}');
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
      case RoomEventAction.barTake:
        returnValue = _barTake(roomEvent.owner, receiver: roomEvent.receiver);
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
