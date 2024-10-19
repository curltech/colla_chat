import 'dart:async';
import 'dart:math';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/majiang/card.dart';
import 'package:colla_chat/pages/majiang/card_util.dart';
import 'package:colla_chat/pages/majiang/participant_card.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/number_util.dart';

enum ParticipantPosition { east, south, west, north }

enum RoomEventAction {
  room, //新房间
  round, //新局
  take, //发牌
  barTake, //杠上发牌
  seaTake, //海底发牌
  send, //打牌
  touch, //碰牌
  bar, //杠牌
  darkBar, //暗杠
  drawing, //吃
  check, //检查
  checkComplete, //检查胡牌
  complete, //胡
  rob, //抢杠胡牌
  seaComplete, //海底捞胡
  pass, //过牌
  score,
}

/// 房间事件，一个房间事件由系统或者某个参与者触发，通知其他参与者，会触发一些检查动作或者其他的事件
/// 比如参与者打牌事件将发送到房间，然后房间分发到所有的参与者
/// 事件处理原则：参与者的事件也是先发送到房间，再分发到所有参与者，然后自己再进行处理，原因是考虑到网络环境
class RoomEvent {
  /// 房间的名称
  final String name;

  /// 事件的拥有者，-1表示房间或者系统，0，1，2，3表示参与者的位置
  final int owner;

  /// RoomAction事件的枚举
  final RoomEventAction action;

  final String? card;

  /// 行为发生的来源参与者，比如0胡了1打出的牌
  final int? src;

  final int? pos;

  /// 每个事件的内容不同，
  /// 新房间事件是一个参与者数组
  /// 新局事件是庄家的位置和一个随机数的数组，代表发牌
  /// 其他的事件都是参与者的事件，表示牌
  final dynamic content;

  RoomEvent(this.name, this.owner, this.action,
      {this.card, this.pos, this.content, this.src});

  RoomEvent.fromJson(Map json)
      : name = json['name'],
        owner = json['owner'],
        action = json['action'],
        card = json['card'],
        pos = json['pos'],
        content = json['content'],
        src = json['src'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'owner': owner,
      'action': action,
      'card': card,
      'pos': pos,
      'content': content,
      'src': src,
    };
  }
}

/// 麻将房间
class MajiangRoom {
  final String name;

  /// 四个参与者的牌，在所有的参与者电脑中都保持一致，所以当前参与者的位置是不固定的
  final List<ParticipantCard> participantCards = [];

  /// 未知的牌
  List<String> unknownCards = [];

  /// 胡牌的分数
  Map<CompleteType, int> completeTypeScores = {
    CompleteType.thirteenOne: 300,
    CompleteType.oneNine: 150,
    CompleteType.pureTouch: 150,
    CompleteType.luxPair7: 150,
    CompleteType.pureOneType: 100,
    CompleteType.mixTouch: 100,
    CompleteType.pair7: 80,
    CompleteType.mixOneType: 60,
    CompleteType.touch: 40,
    CompleteType.small: 10,
  };

  /// 庄家
  int? banker;

  /// 当前的持有发牌的参与者
  int? keeper;

  /// 刚出牌的参与者
  int? sender;

  String? sendCard;

  /// 同圈放弃的胡牌
  int? giveUp;
  String? giveUpCard;

  int? robber;
  String? robCard;

  /// 正在等待做出决定的参与者，如果为空，则房间发牌，
  /// 如果都是pass消解等待的，则发牌，有一家是非pass消解的不发牌
  List<int> waiting = [];

  late final int current;

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  MajiangRoom(this.name);

  /// 加参与者，第一个是自己，第二个是下家，第三个是对家，第四个是上家
  Future<void> init(List<String> peerIds) async {
    for (int i = 0; i < peerIds.length; ++i) {
      String peerId = peerIds[i];
      if (myself.peerId == peerId) {
        current = i;
      }
      Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
      String linkmanName =
          linkman == null ? AppLocalizations.t('unknown') : linkman.name;
      ParticipantCard participantCard =
          ParticipantCard(peerId, linkmanName, i, name);
      participantCard.avatarWidget =
          linkman == null ? AppImage.mdAppImage : linkman.avatarImage;
      participantCard.avatarWidget ??= AppImage.mdAppImage;
      participantCards.add(participantCard);
    }
    if (peerIds.length < 4) {
      for (int i = peerIds.length; i < 4; i++) {
        ParticipantCard participantCard = ParticipantCard(
          'robot$i',
          '${AppLocalizations.t('robot')}$i',
          i,
          name,
          robot: true,
        );
        participantCard.avatarWidget ??= AppImage.mdAppImage;
        participantCards.add(participantCard);
      }
    }

    /// 房间池分发到房间的事件自己也需要监听
    roomEventStreamSubscription =
        roomEventStreamController.stream.listen((RoomEvent roomEvent) {
      onRoomEvent(roomEvent);
    });
  }

  int? get(String peerId) {
    for (int i = 0; i < participantCards.length; i++) {
      ParticipantCard participantCard = participantCards[i];
      if (participantCard.peerId == peerId) {
        return i;
      }
    }
    return null;
  }

  /// 下家
  int next(int pos) {
    if (pos == participantCards.length - 1) {
      return 0;
    }
    return pos + 1;
  }

  /// 上家
  int previous(int pos) {
    if (pos == 0) {
      return participantCards.length - 1;
    }
    return pos - 1;
  }

  /// 对家
  int opponent(int pos) {
    if (pos == 0) {
      return 2;
    }
    if (pos == 1) {
      return 3;
    }
    if (pos == 2) {
      return 0;
    }
    if (pos == 3) {
      return 1;
    }
    throw 'error position';
  }

  /// 新玩一局，positions为空自己发牌，不为空，别人发牌
  List<int> _round({List<int>? randoms}) {
    for (var participantCard in participantCards) {
      participantCard.clear();
    }
    unknownCards.clear();
    banker = null;
    keeper = null;
    sendCard = null;
    sender = null;
    List<String> allCards = [...cardConcept.allCards];
    Random random = Random.secure();
    randoms ??= [];

    /// 如果没有指定庄家，开新局的参与者就是庄家，否则设定庄家
    int length = randoms.length;
    if (length == 137) {
      banker = randoms[136];
      keeper = banker;
    } else {
      banker = 0;
      keeper = banker;
    }
    for (int i = 0; i < 136; ++i) {
      int pos;
      if (i < randoms.length) {
        pos = randoms[i];
      } else {
        pos = random.nextInt(allCards.length);
        randoms.add(pos);
      }
      String card = allCards.removeAt(pos);

      /// 每个参与者发13张牌
      if (i < 52) {
        int reminder = (i + banker!) % 4;
        participantCards[reminder].handCards.add(card);
      } else {
        unknownCards.add(card);
      }
    }
    length = randoms.length;
    if (length == 136) {
      randoms.add(banker!);
    }

    /// 自己的牌现排序
    for (var participantCard in participantCards) {
      participantCard.handSort();
    }

    _take(banker!);

    return randoms;
  }

  /// 打牌
  bool _send(int owner, String card) {
    if (owner != keeper) {
      return false;
    }
    bool pass = true;
    ParticipantCard participantCard = participantCards[owner];
    int? pos = participantCard
        .onRoomEvent(RoomEvent(name, owner, RoomEventAction.send, card: card));
    for (int i = 0; i < participantCards.length; ++i) {
      if (i != owner) {
        participantCard = participantCards[i];
        pos = participantCard.onRoomEvent(
            RoomEvent(name, owner, RoomEventAction.send, card: card));
        if (pos != null) {
          pass = false;
        }
      }
    }
    sender = owner;
    sendCard = card;
    keeper = null;
    if (pass) {
      onRoomEvent(RoomEvent(name, next(owner), RoomEventAction.take));
    }

    return true;
  }

  /// 杠牌发牌
  String? _barTake(int owner) {
    if (unknownCards.isEmpty) {
      return null;
    }
    int barCount = 0;
    for (var participantCard in participantCards) {
      barCount += participantCard.barCount;
    }
    int mod = barCount % 2;
    String card;
    if (mod == 0 && unknownCards.length > 1) {
      card = unknownCards.removeAt(unknownCards.length - 2);
    } else {
      card = unknownCards.removeLast();
    }
    sender = null;
    sendCard = null;
    keeper = owner;
    ParticipantCard participantCard = participantCards[owner];
    participantCard.onRoomEvent(RoomEvent(name, owner, RoomEventAction.take,
        card: card, pos: TakeCardType.bar.index));
    for (int i = 0; i < participantCards.length; ++i) {
      if (i != owner) {
        participantCard = participantCards[i];
        participantCard.onRoomEvent(RoomEvent(name, owner, RoomEventAction.take,
            card: card, pos: TakeCardType.bar.index));
      }
    }

    return card;
  }

  /// 发牌
  String? _take(int owner) {
    if (unknownCards.isEmpty) {
      return null;
    }
    String card = unknownCards.removeLast();
    sender = null;
    sendCard = null;
    keeper = owner;
    TakeCardType takeCardType = TakeCardType.self;
    if (unknownCards.length < 5) {
      takeCardType = TakeCardType.sea;
    }
    ParticipantCard participantCard = participantCards[owner];
    participantCard.onRoomEvent(RoomEvent(name, owner, RoomEventAction.take,
        card: card, pos: takeCardType.index));
    for (int i = 0; i < participantCards.length; ++i) {
      if (i != owner) {
        ParticipantCard participantCard = participantCards[i];
        participantCard.onRoomEvent(RoomEvent(name, owner, RoomEventAction.take,
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
    for (int i = 0; i < participantCards.length; ++i) {
      ParticipantCard participant = participantCards[owner];
      if (participant.participantState.containsKey(ParticipantState.complete)) {
        giveUp = owner;
        giveUpCard = sendCard;
      }
    }
    robber = null;
    robCard = null;
    for (int i = 0; i < participantCards.length; ++i) {
      ParticipantCard participantCard = participantCards[i];
      participantCard.onRoomEvent(RoomEvent(name, owner, RoomEventAction.pass));
    }

    return true;
  }

  /// 某个参与者碰打出的牌
  bool _touch(int owner, int pos, int src, String sendCard) {
    for (int i = 0; i < participantCards.length; ++i) {
      ParticipantCard participantCard = participantCards[i];
      participantCard.onRoomEvent(RoomEvent(name, owner, RoomEventAction.touch,
          card: sendCard, src: src, pos: pos));
    }
    if (participantCards[owner].touchCards.length == 4) {
      participantCards[owner].packer = sender;
    }
    participantCards[sender!].poolCards.removeLast();
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

    for (int i = 0; i < participantCards.length; ++i) {
      ParticipantCard participantCard = participantCards[i];
      participantCard.onRoomEvent(RoomEvent(name, owner, RoomEventAction.bar,
          src: sender, card: sendCard, pos: pos));
    }
    if (sender != null) {
      participantCards[sender!].poolCards.removeLast();
      if (participantCards[owner].touchCards.length == 4) {
        participantCards[owner].packer = sender;
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

  Map<int, CompleteType>? _checkComplete(int owner, String card) {
    Map<int, CompleteType>? completeTypes;
    for (int i = 0; i < participantCards.length; ++i) {
      if (owner != i) {
        ParticipantCard participantCard = participantCards[i];
        CompleteType? completeType = participantCard.onRoomEvent(
            RoomEvent(name, owner, RoomEventAction.checkComplete, card: card));
        if (completeType != null) {
          completeTypes ??= {};
          completeTypes[i] = completeType;
        }
      }
    }

    return completeTypes;
  }

  /// owner抢src的明杠牌card
  _rob(int owner, int src, String card) {}

  /// 某个参与者暗杠，pos表示杠牌的位置
  String? _darkBar(int owner, int pos) {
    ParticipantCard participantCard = participantCards[owner];
    String? card = participantCard
        .onRoomEvent(RoomEvent(name, owner, RoomEventAction.darkBar, pos: pos));
    if (card == null) {
      return null;
    }
    for (int i = 0; i < participantCards.length; ++i) {
      if (owner != i) {
        ParticipantCard participantCard = participantCards[i];
        participantCard.onRoomEvent(
            RoomEvent(name, owner, RoomEventAction.darkBar, pos: pos));
      }
    }
    _barTake(owner);

    return card;
  }

  /// 某个参与者吃打出的牌，pos表示吃牌的位置
  String? _drawing(int owner, int pos) {
    if (sendCard == null) {
      return null;
    }
    ParticipantCard participantCard = participantCards[owner];
    String? card = participantCard.onRoomEvent(RoomEvent(
        name, owner, RoomEventAction.drawing,
        pos: pos, card: sendCard));
    if (card == null) {
      return card;
    }
    for (int i = 0; i < participantCards.length; ++i) {
      if (owner != i) {
        ParticipantCard participantCard = participantCards[i];
        participantCard.onRoomEvent(
            RoomEvent(name, owner, RoomEventAction.darkBar, pos: pos));
      }
    }
    participantCards[sender!].poolCards.removeLast();
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
    int? baseScore = completeTypeScores[completeType];
    if (baseScore == null) {
      return false;
    }
    ParticipantCard participantCard = participantCards[owner];
    if (robber != null && robCard != null) {
      participantCard.score.value += baseScore * 3;
      participantCards[robber!].score.value -= baseScore * 3;
    } else if (participantCard.takeCardType == TakeCardType.bar ||
        participantCard.takeCardType == TakeCardType.sea) {
      baseScore = baseScore * 2;
      participantCard.score.value += baseScore * 3;
    } else if (participantCard.takeCardType == TakeCardType.self) {
      participantCard.score.value += baseScore * 3;
    } else {
      participantCard.score.value += baseScore;
    }
    if (sender != null) {
      participantCards[sender!].score.value -= baseScore;
    } else {
      if (participantCard.packer != null) {
        ParticipantCard pc = participantCards[participantCard.packer!];
        pc.score.value -= 3 * baseScore;
      } else {
        for (int i = 0; i < participantCards.length; ++i) {
          if (i != owner) {
            ParticipantCard participantCard = participantCards[i];
            participantCard.score.value -= baseScore;
          }
        }
      }
    }

    for (int i = 0; i < participantCards.length; ++i) {
      ParticipantCard participantCard = participantCards[i];
      for (var sender in participantCard.barSenders) {
        participantCard.score.value += 10;
        participantCards[sender].score.value -= 10;
      }
    }

    return true;
  }

  /// 某个参与者胡牌
  CompleteType? _complete(int owner) {
    ParticipantCard participantCard = participantCards[owner];
    CompleteType? completeType = participantCard.onRoomEvent(
        RoomEvent(name, owner, RoomEventAction.complete, card: sendCard));
    if (completeType == null) {
      return null;
    }
    for (int i = 0; i < participantCards.length; ++i) {
      if (owner != i) {
        ParticipantCard participantCard = participantCards[i];
        participantCard.onRoomEvent(
            RoomEvent(name, owner, RoomEventAction.complete, card: sendCard));
      }
    }
    banker = owner;

    return completeType;
  }

  /// 房间的事件有外部触发，所有订阅者都会触发监听事件，本方法由外部调用，比如外部的消息chatMessage
  dynamic onRoomEvent(RoomEvent roomEvent) async {
    switch (roomEvent.action) {
      case RoomEventAction.room:
        break;
      case RoomEventAction.round:
        List<int>? randoms;
        String? content = roomEvent.content;
        if (content != null) {
          randoms = JsonUtil.toJson(content);
        }
        _round(randoms: randoms);
        break;
      case RoomEventAction.take:
        _take(roomEvent.owner);
        break;
      case RoomEventAction.barTake:
        _barTake(roomEvent.owner);
        break;
      case RoomEventAction.seaTake:
        _take(roomEvent.owner);
        break;
      case RoomEventAction.send:
        _send(roomEvent.owner, roomEvent.card!);
        break;
      case RoomEventAction.touch:
        _touch(
            roomEvent.owner, roomEvent.pos!, roomEvent.src!, roomEvent.card!);
        break;
      case RoomEventAction.bar:
        _bar(roomEvent.owner, roomEvent.pos!);
        break;
      case RoomEventAction.darkBar:
        _darkBar(roomEvent.owner, roomEvent.pos!);
        break;
      case RoomEventAction.drawing:
        _drawing(roomEvent.owner, roomEvent.pos!);
        break;
      case RoomEventAction.complete:
        return _complete(roomEvent.owner);
      case RoomEventAction.pass:
        _pass(roomEvent.owner);
        break;
      case RoomEventAction.score:
        _score(roomEvent.owner, roomEvent.pos!);
        break;
      case RoomEventAction.rob:
        _rob(roomEvent.owner, roomEvent.src!, roomEvent.card!);
        break;
      default:
        break;
    }
  }
}
