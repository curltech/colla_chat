import 'dart:math';

import 'package:colla_chat/pages/game/majiang/base/RoundParticipant.dart';
import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/full_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/participant.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/stock_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';
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
  int? banker;

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

  late final int currentRoundParticipant;

  /// 本轮的随机洗牌数组
  late List<int> randoms;

  Round(this.id, this.room, {List<int>? randoms}) {
    List<Card> stockCards = [];
    for (int i = 0; i < 4; ++i) {
      stockCards.addAll(fullPile.cards);
    }
    stockPile = StockPile(cards: stockCards);
    for (int i = 0; i < room.participants.length; ++i) {
      Participant participant = room.participants[i];
      RoundParticipant roundParticipant =
          RoundParticipant(i, this, participant);
      roundParticipants.add(roundParticipant);
    }
    if (randoms == null) {
      this.randoms = [];
    } else {
      this.randoms = randoms;
    }
    init();
  }

  init() {
    /// 如果没有指定庄家，开新局的参与者就是庄家，否则设定庄家
    int length = randoms.length;
    if (length == 137) {
      banker = randoms[136];
      keeper = banker;
    } else {
      banker = 0;
      keeper = banker;
    }

    Random random = Random.secure();
    for (int i = 0; i < 136; ++i) {
      int pos;
      if (i < randoms.length) {
        pos = randoms[i];
      } else {
        pos = random.nextInt(stockPile.cards.length);
        randoms.add(pos);
      }
      Card card = stockPile.cards.removeAt(pos);

      /// 每个参与者发13张牌
      if (i < 52) {
        int reminder = (i + banker!) % 4;
        roundParticipants[reminder].handPile.cards.add(card);
      }
    }
    length = randoms.length;
    if (length == 136) {
      randoms.add(banker!);
    }

    /// 手牌排序
    for (var roundParticipant in roundParticipants) {
      roundParticipant.handPile.sort();
    }

    _take(banker!);
  }

  /// 打牌
  bool _send(int owner, Card card) {
    if (owner != keeper) {
      return false;
    }
    bool pass = true;
    RoundParticipant roundParticipant = roundParticipants[owner];
    int? pos = roundParticipant.onRoomEvent(
        RoomEvent(room.name, id, owner, RoomEventAction.send, card: card));
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i != owner) {
        roundParticipant = roundParticipants[i];
        pos = roundParticipant.onRoomEvent(
            RoomEvent(room.name, id, owner, RoomEventAction.send, card: card));
        if (pos != null) {
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
    int barCount = 0;
    for (var roundParticipant in roundParticipants) {
      // barCount += roundParticipant.barCount;
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
        room.name, id, owner, RoomEventAction.take,
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

  /// 发牌
  Card? _take(int owner) {
    if (stockPile.cards.isEmpty) {
      return null;
    }
    Card card = stockPile.cards.removeLast();
    sender = null;
    sendCard = null;
    keeper = owner;
    TakeCardType takeCardType = TakeCardType.self;
    if (stockPile.cards.length < 5) {
      takeCardType = TakeCardType.sea;
    }
    RoundParticipant roundParticipant = roundParticipants[owner];
    roundParticipant.onRoomEvent(RoomEvent(
        room.name, id, owner, RoomEventAction.take,
        card: card, pos: takeCardType.index));
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (i != owner) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(RoomEvent(
            room.name, id, owner, RoomEventAction.take,
            card: card, pos: takeCardType.index));
      }
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
    roundParticipants[sender!].wastePile.cards.removeLast();
    keeper = owner;
    sender = null;
    this.sendCard = null;

    return true;
  }

  /// 某个参与者杠打出的牌，pos表示可杠的手牌的位置
  /// 明杠牌，分三种情况 pos为-1，表示是摸牌可杠，否则表示手牌可杠的位置 返回值为杠的牌，为空表示未成功
  String? _bar(int owner, int pos) {
    bool canRob = false;
    Map<int, CompleteType>? completeTypes = _checkComplete(owner, sendCard!);
    if (completeTypes != null) {
      canRob = true;
      robber = owner;
      robCard = sendCard;
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
      for (var sender in roundParticipant.barSenders) {
        roundParticipant.score.value += 10;
        roundParticipants[sender].score.value -= 10;
      }
    }

    return true;
  }

  /// 某个参与者胡牌
  CompleteType? _complete(int owner) {
    RoundParticipant roundParticipant = roundParticipants[owner];
    CompleteType? completeType = roundParticipant.onRoomEvent(RoomEvent(
        room.name, id, owner, RoomEventAction.complete,
        card: sendCard));
    if (completeType == null) {
      return null;
    }
    for (int i = 0; i < roundParticipants.length; ++i) {
      if (owner != i) {
        RoundParticipant roundParticipant = roundParticipants[i];
        roundParticipant.onRoomEvent(RoomEvent(
            room.name, id, owner, RoomEventAction.complete,
            card: sendCard));
      }
    }
    banker = owner;

    return completeType;
  }

  dynamic onRoomEvent(RoomEvent roomEvent) async {}
}
