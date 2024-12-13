import 'dart:math';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/room_pool.dart';
import 'package:colla_chat/pages/game/majiang/base/round_participant.dart';
import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/full_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/outstanding_action.dart';
import 'package:colla_chat/pages/game/majiang/base/participant.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/stock_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/number_util.dart';

/// 摸牌的类型：自摸牌，杠上牌，海底捞
enum TakeCardType { self, bar, sea }

/// 每一轮，每轮有四个轮参与者
class Round {
  /// 每轮的编号，在房间中按次序增长
  int id;

  /// 所属的房间
  late final Room room;

  /// 未使用的牌
  late final StockPile stockPile;

  final List<RoundParticipant> roundParticipants = [];

  /// 庄家
  int banker;

  /// 刚出牌的参与者
  int? sender;

  Card? sendCard;

  /// 同圈放弃的胡牌
  int? giveUp;
  Card? giveUpCard;

  int? robber;
  Card? robCard;

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
          roundParticipants[i].handPile.cards = handPile!.cards;
        } else {
          roundParticipants[i].handPile.cards = [];
          for (int j = 0; j < 13; ++j) {
            roundParticipants[i].handPile.cards.add(unknownCard);
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
    List<Card> stockCards = [
      ...fullPile.cards,
      ...fullPile.cards,
      ...fullPile.cards,
      ...fullPile.cards
    ];
    stockPile = StockPile();
    Random random = Random.secure();

    /// 牌的总数是136
    for (int i = 0; i < 136; ++i) {
      int pos = random.nextInt(stockCards.length);
      Card card = stockCards.removeAt(pos);

      /// 每个参与者发13张牌
      if (i < 52) {
        int reminder = (i + banker) % 4;
        roundParticipants[reminder].handPile.cards.add(card);
      } else {
        stockPile.cards.add(card);
      }
    }

    /// 手牌排序
    for (var roundParticipant in roundParticipants) {
      roundParticipant.handPile.sort();
    }

    _take(banker);
  }

  RoundParticipant getRoundParticipant(
      ParticipantDirection participantDirection) {
    return roundParticipants[participantDirection.index];
  }

  int get total {
    int total = 0;
    for (int i = 0; i < roundParticipants.length; ++i) {
      total += roundParticipants[i].total;
    }
    return total + stockPile.cards.length;
  }

  /// 打牌，每个参与者都要执行一次
  /// owner表示打牌的参与者，receiver代表接收到事件的参与者
  Map<OutstandingAction, Set<int>>? _send(int owner, Card card,
      {int? receiver}) {
    /// 打牌的参与者执行事件处理
    RoundParticipant roundParticipant;
    if (receiver == null) {
      roundParticipant = roundParticipants[owner];
    } else {
      roundParticipant = roundParticipants[receiver];
    }
    sender = owner;
    sendCard = card;

    return roundParticipant.onRoomEvent(RoomEvent(room.name,
        roundId: id, owner: owner, action: RoomEventAction.send, card: card));
  }

  /// 杠牌发牌
  Card? _barTake(int owner, {int? receiver}) {
    if (stockPile.cards.isEmpty) {
      return null;
    }
    int mod = barCount % 2;
    Card card;
    if (mod == 0 && stockPile.cards.length > 1) {
      card = stockPile.cards.removeAt(stockPile.cards.length - 2);
    } else {
      card = stockPile.cards.removeLast();
    }
    sender = null;
    sendCard = null;
    RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.onRoomEvent(RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.barTake,
        card: card,
        pos: TakeCardType.bar.index));
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i != owner) {
        roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.take,
            card: card,
            pos: TakeCardType.bar.index));
      }
    }

    return card;
  }

  bool get isSeaTake {
    return stockPile.cards.length < 5;
  }

  /// 发牌
  Card? _take(int owner, {int? receiver}) {
    if (stockPile.cards.isEmpty) {
      logger.e('owner:$owner take card failure, stockPile is empty');
      return null;
    }

    TakeCardType takeCardType = TakeCardType.self;
    if (isSeaTake) {
      takeCardType = TakeCardType.sea;
    }
    Card card = stockPile.cards.removeLast();
    logger.w(
        'take card ${card.toString()}, leave ${stockPile.cards.length} cards');
    sender = null;
    sendCard = null;
    RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.onRoomEvent(RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.take,
        card: card,
        pos: takeCardType.index));

    return card;
  }

  /// 某个参与者过，没有采取任何行为
  bool _pass(int owner, {int? receiver}) {
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[owner];
      if (roundParticipant.outstandingActions
          .containsKey(OutstandingAction.complete)) {
        giveUp = owner;
        giveUpCard = sendCard;
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
          roundId: id, owner: room.next(owner), action: RoomEventAction.take));
    }

    return true;
  }

  /// 某个参与者碰打出的牌
  bool _touch(int owner, int pos, int src, Card sendCard, {int? receiver}) {
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roundParticipant.onRoomEvent(RoomEvent(room.name,
          roundId: id,
          owner: owner,
          action: RoomEventAction.touch,
          card: sendCard,
          src: src,
          pos: pos));
    }
    if (roundParticipants[owner].handPile.touchPiles.length == 4) {
      roundParticipants[owner].packer = sender;
    }
    if (sender != null) {
      List<Card> cards = roundParticipants[sender!].wastePile.cards;
      if (cards.isNotEmpty) {
        cards.removeLast();
      }
    }
    sender = null;
    this.sendCard = null;

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
    if (sendCard != null) {
      Map<int, CompleteType>? completeTypes =
          _checkComplete(owner, sendCard!, receiver: receiver);
      if (completeTypes != null) {
        canRob = true;
        robber = owner;
        robCard = sendCard;
      }
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roundParticipant.onRoomEvent(RoomEvent(room.name,
          roundId: id,
          owner: owner,
          action: RoomEventAction.bar,
          src: sender,
          card: sendCard,
          pos: pos));
    }
    if (sender != null) {
      roundParticipants[sender!].wastePile.cards.removeLast();
      if (roundParticipants[owner].handPile.touchPiles.length == 4) {
        roundParticipants[owner].packer = sender;
      }
    }
    sender = null;
    sendCard = null;
    if (canRob) {
      return null;
    }

    _barTake(owner);

    return null;
  }

  Map<int, CompleteType>? _checkComplete(int owner, Card card,
      {int? receiver}) {
    Map<int, CompleteType>? completeTypes;
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        CompleteType? completeType = roundParticipant.onRoomEvent(RoomEvent(
            room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.checkComplete,
            card: card));
        if (completeType != null) {
          completeTypes ??= {};
          completeTypes[i] = completeType;
        }
      }
    }

    return completeTypes;
  }

  /// owner抢src的明杠牌card
  _rob(int owner, int src, Card card, {int? receiver}) {}

  /// 某个参与者暗杠，pos表示杠牌的位置
  Card? _darkBar(int owner, int pos, {int? receiver}) {
    RoundParticipant roundParticipant = roundParticipants[owner];
    Card? card = roundParticipant.onRoomEvent(RoomEvent(room.name,
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
  Card? _drawing(int owner, int pos, {int? receiver}) {
    if (sendCard == null) {
      return null;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    Card? card = roundParticipant.onRoomEvent(RoomEvent(room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.drawing,
        pos: pos,
        card: sendCard));
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
    roundParticipants[sender!].wastePile.cards.removeLast();
    sender = null;
    sendCard = null;

    return card;
  }

  bool _score(int owner, int completeTypeIndex, {int? receiver}) {
    CompleteType? completeType =
        NumberUtil.toEnum(CompleteType.values, completeTypeIndex);
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
    } else if (roundParticipant.handPile.takeCardType == TakeCardType.bar ||
        roundParticipant.handPile.takeCardType == TakeCardType.sea) {
      baseScore = baseScore * 2;
      roundParticipant.score.value += baseScore * 3;
    } else if (roundParticipant.handPile.takeCardType == TakeCardType.self) {
      roundParticipant.score.value += baseScore * 3;
    } else {
      roundParticipant.score.value += baseScore;
    }
    if (sender != null) {
      roundParticipants[sender!].score.value -= baseScore;
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
  CompleteType? _complete(int owner, int pos, {int? receiver}) {
    RoundParticipant roundParticipant = roundParticipants[owner];
    CompleteType? completeType = roundParticipant.onRoomEvent(RoomEvent(
        room.name,
        roundId: id,
        owner: owner,
        action: RoomEventAction.complete,
        pos: pos,
        card: sendCard));
    if (completeType == null) {
      return null;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(RoomEvent(room.name,
            roundId: id,
            owner: owner,
            action: RoomEventAction.complete,
            pos: pos,
            card: sendCard));
      }
    }
    room.banker = owner;

    return completeType;
  }

  /// 发起房间的事件，由发起事件的参与者调用
  /// 完成后把事件分发到其他参与者
  dynamic startRoomEvent(RoomEvent roomEvent) async {
    dynamic returnValue = onRoomEvent(roomEvent);
    for (int i = 0; i < roundParticipants.length; i++) {
      RoundParticipant roundParticipant = roundParticipants[i];
      if (roundParticipant.participant.peerId != myself.peerId) {
        roomEvent.receiver = i;
        ChatMessage chatMessage = await chatMessageService.buildChatMessage(
            receiverPeerId: roundParticipant.participant.peerId,
            subMessageType: ChatMessageSubType.majiang,
            content: roomEvent);
        if (roundParticipant.participant.robot) {
          roomPool.onRoomEvent(chatMessage);
        } else {
          roomPool.send(chatMessage);
        }
      }
    }

    return returnValue;
  }

  dynamic onRoomEvent(RoomEvent roomEvent) async {
    logger.w('round:$id has received event:${roomEvent.toString()}');
    dynamic returnValue;
    RoomEventAction? action = roomEvent.action;
    switch (action) {
      case RoomEventAction.take:
        returnValue = _take(roomEvent.owner, receiver: roomEvent.receiver);
      case RoomEventAction.send:
        returnValue = _send(roomEvent.owner, roomEvent.card!,
            receiver: roomEvent.receiver);
      case RoomEventAction.bar:
        returnValue =
            _bar(roomEvent.owner, roomEvent.pos!, receiver: roomEvent.receiver);
      case RoomEventAction.barTake:
        returnValue = _barTake(roomEvent.owner, receiver: roomEvent.receiver);
      case RoomEventAction.touch:
        returnValue = _touch(
            roomEvent.owner, roomEvent.pos!, roomEvent.src!, roomEvent.card!,
            receiver: roomEvent.receiver);
      case RoomEventAction.darkBar:
        returnValue = _darkBar(roomEvent.owner, roomEvent.pos!,
            receiver: roomEvent.receiver);
      case RoomEventAction.drawing:
        returnValue = _drawing(roomEvent.owner, roomEvent.pos!,
            receiver: roomEvent.receiver);
      case RoomEventAction.rob:
        returnValue = _rob(roomEvent.owner, roomEvent.src!, roomEvent.card!,
            receiver: roomEvent.receiver);
      case RoomEventAction.score:
        returnValue = _score(roomEvent.owner, roomEvent.pos!,
            receiver: roomEvent.receiver);
      case RoomEventAction.pass:
        returnValue = _pass(roomEvent.owner, receiver: roomEvent.receiver);
      case RoomEventAction.complete:
        returnValue = _complete(roomEvent.owner, roomEvent.pos!,
            receiver: roomEvent.receiver);
      default:
        break;
    }

    if (roomEvent.action == RoomEventAction.send) {
      roomController.majiangFlameGame.reloadNext();
    }
    roomController.majiangFlameGame.reloadSelf();

    return returnValue;
  }
}
