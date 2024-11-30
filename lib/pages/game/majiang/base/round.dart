import 'dart:math';

import 'package:colla_chat/pages/game/majiang/base/round_participant.dart';
import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/full_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/outstanding_action.dart';
import 'package:colla_chat/pages/game/majiang/base/participant.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/stock_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/number_util.dart';

/// 摸牌的类型：自摸牌，杠上牌，海底捞
enum TakeCardType { self, bar, sea }

/// 每一轮，每轮有四个轮参与者
class Round {
  /// 每轮的编号，在房间中按次序增长
  int id;

  /// 所属的房间
  final Room room;

  /// 未使用的牌
  late final StockPile stockPile;

  final List<RoundParticipant> roundParticipants = [];

  /// 庄家
  int banker;

  /// 当前的持有发牌的参与者
  int? keeper;

  /// 刚出牌的参与者
  int? sender;

  Card? sendCard;

  /// 同圈放弃的胡牌
  int? giveUp;
  Card? giveUpCard;

  int? robber;
  Card? robCard;

  /// 正在等待做出决定的参与者，如果为空，则房间发牌，
  /// 如果都是pass消解等待的，则发牌，有一家是非pass消解的不发牌
  List<int> waiting = [];

  /// 本轮的随机洗牌数组
  late List<int> randoms;

  Round(this.id, this.room, this.banker, {List<int>? randoms}) {
    if (randoms == null) {
      this.randoms = [];
    } else {
      this.randoms = randoms;
    }
    keeper = banker;

    init();
  }

  init() {
    for (int i = 0; i < room.participants.length; ++i) {
      Participant participant = room.participants[i];
      RoundParticipant roundParticipant =
          RoundParticipant(i, this, participant);
      roundParticipants.add(roundParticipant);
    }
    List<Card> stockCards = [
      ...fullPile.cards,
      ...fullPile.cards,
      ...fullPile.cards,
      ...fullPile.cards
    ];
    stockPile = StockPile();
    Random random = Random.secure();
    /// 牌的总数是136
    for (int i = 0; i < 58; ++i) {
      int pos;
      if (i < randoms.length) {
        pos = randoms[i];
      } else {
        pos = random.nextInt(stockCards.length);
        randoms.add(pos);
      }
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

  /// 打牌
  bool _send(int owner, Card card) {
    if (owner != keeper) {
      return false;
    }
    bool pass = true;
    RoundParticipant roundParticipant = roundParticipants[owner];
    Map<OutstandingAction, List<int>>? outstandingActions =
        roundParticipant.onRoomEvent(
            RoomEvent(room.name, id, owner, RoomEventAction.send, card: card));
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i != owner) {
        roundParticipant = roundParticipants[i];
        outstandingActions = roundParticipant.onRoomEvent(
            RoomEvent(room.name, id, owner, RoomEventAction.send, card: card));
        if (outstandingActions != null) {
          pass = false;
        }
      }
    }
    sender = owner;
    sendCard = card;
    keeper = null;
    if (pass) {
      onRoomEvent(
          RoomEvent(room.name, id, room.next(owner), RoomEventAction.take));
    }

    return true;
  }

  /// 杠牌发牌
  Card? _barTake(int owner) {
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
    keeper = owner;
    RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.onRoomEvent(RoomEvent(
        room.name, id, owner, RoomEventAction.barTake,
        card: card, pos: TakeCardType.bar.index));
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i != owner) {
        roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(RoomEvent(
            room.name, id, owner, RoomEventAction.take,
            card: card, pos: TakeCardType.bar.index));
      }
    }

    return card;
  }

  bool get isSeaTake {
    return stockPile.cards.length < 5;
  }

  /// 发牌
  Card? _take(int owner) {
    if (stockPile.cards.isEmpty) {
      return null;
    }

    Card card = stockPile.cards.removeLast();
    logger.w(
        'take card ${card.toString()}, leave ${stockPile.cards.length} cards');
    sender = null;
    sendCard = null;
    keeper = owner;
    TakeCardType takeCardType = TakeCardType.self;
    if (isSeaTake) {
      takeCardType = TakeCardType.sea;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roundParticipant.onRoomEvent(RoomEvent(
          room.name, id, owner, RoomEventAction.take,
          card: card, pos: takeCardType.index));
    }

    return card;
  }

  /// 某个参与者过，没有采取任何行为
  bool _pass(int owner) {
    if (sender == null) {
      return false;
    }
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
      roundParticipant
          .onRoomEvent(RoomEvent(room.name, id, owner, RoomEventAction.pass));
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
      onRoomEvent(
          RoomEvent(room.name, id, room.next(sender!), RoomEventAction.take));
    }

    return true;
  }

  /// 某个参与者碰打出的牌
  bool _touch(int owner, int pos, int src, Card sendCard) {
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roundParticipant.onRoomEvent(RoomEvent(
          room.name, id, owner, RoomEventAction.touch,
          card: sendCard, src: src, pos: pos));
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
    keeper = owner;
    sender = null;
    this.sendCard = null;

    return true;
  }

  int get barCount {
    int c = 0;
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      List<List<int>> counts = roundParticipant.earnedActions.values.toList();
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
  String? _bar(int owner, int pos) {
    /// 检查抢杠
    bool canRob = false;
    if (sendCard != null) {
      Map<int, CompleteType>? completeTypes = _checkComplete(owner, sendCard!);
      if (completeTypes != null) {
        canRob = true;
        robber = owner;
        robCard = sendCard;
      }
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      RoundParticipant roundParticipant = roundParticipants[i];
      roundParticipant.onRoomEvent(RoomEvent(
          room.name, id, owner, RoomEventAction.bar,
          src: sender, card: sendCard, pos: pos));
    }
    if (sender != null) {
      roundParticipants[sender!].wastePile.cards.removeLast();
      if (roundParticipants[owner].handPile.touchPiles.length == 4) {
        roundParticipants[owner].packer = sender;
      }
    }
    keeper = owner;
    sender = null;
    sendCard = null;
    if (canRob) {
      return null;
    }

    _barTake(owner);

    return null;
  }

  Map<int, CompleteType>? _checkComplete(int owner, Card card) {
    Map<int, CompleteType>? completeTypes;
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        CompleteType? completeType = roundParticipant.onRoomEvent(RoomEvent(
            room.name, id, owner, RoomEventAction.checkComplete,
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
  _rob(int owner, int src, Card card) {}

  /// 某个参与者暗杠，pos表示杠牌的位置
  Card? _darkBar(int owner, int pos) {
    RoundParticipant roundParticipant = roundParticipants[owner];
    Card? card = roundParticipant.onRoomEvent(
        RoomEvent(room.name, id, owner, RoomEventAction.darkBar, pos: pos));
    if (card == null) {
      return null;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(
            RoomEvent(room.name, id, owner, RoomEventAction.darkBar, pos: pos));
      }
    }
    _barTake(owner);

    return card;
  }

  /// 某个参与者吃打出的牌，pos表示吃牌的位置
  Card? _drawing(int owner, int pos) {
    if (sendCard == null) {
      return null;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    Card? card = roundParticipant.onRoomEvent(RoomEvent(
        room.name, id, owner, RoomEventAction.drawing,
        pos: pos, card: sendCard));
    if (card == null) {
      return card;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(
            RoomEvent(room.name, id, owner, RoomEventAction.darkBar, pos: pos));
      }
    }
    roundParticipants[sender!].wastePile.cards.removeLast();
    keeper = owner;
    sender = null;
    sendCard = null;

    return card;
  }

  bool _score(int owner, int completeTypeIndex) {
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
          List<int> participants = entry.value;
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
  CompleteType? _complete(int owner, int pos) {
    RoundParticipant roundParticipant = roundParticipants[owner];
    CompleteType? completeType = roundParticipant.onRoomEvent(RoomEvent(
        room.name, id, owner, RoomEventAction.complete,
        pos: pos, card: sendCard));
    if (completeType == null) {
      return null;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(RoomEvent(
            room.name, id, owner, RoomEventAction.complete,
            pos: pos, card: sendCard));
      }
    }
    banker = owner;

    return completeType;
  }

  dynamic onRoomEvent(RoomEvent roomEvent) async {
    RoomEventAction action = roomEvent.action;
    switch (action) {
      case RoomEventAction.take:
        return _take(roomEvent.owner);
      case RoomEventAction.send:
        return _send(roomEvent.owner, roomEvent.card!);
      case RoomEventAction.bar:
        return _bar(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.barTake:
        return _barTake(roomEvent.owner);
      case RoomEventAction.touch:
        return _touch(
            roomEvent.owner, roomEvent.pos!, roomEvent.src!, roomEvent.card!);
      case RoomEventAction.darkBar:
        return _darkBar(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.drawing:
        return _drawing(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.rob:
        return _rob(roomEvent.owner, roomEvent.src!, roomEvent.card!);
      case RoomEventAction.score:
        return _score(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.pass:
        return _pass(roomEvent.owner);
      case RoomEventAction.complete:
        return _complete(roomEvent.owner, roomEvent.pos!);
      default:
        break;
    }
  }
}
