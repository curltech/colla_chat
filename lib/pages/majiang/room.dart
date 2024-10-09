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
  complete, //胡
  rob, //抢杠胡牌
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

  /// 每个事件的内容不同，
  /// 新房间事件是一个参与者数组
  /// 新局事件是庄家的位置和一个随机数的数组，代表发牌
  /// 其他的事件都是参与者的事件，表示牌
  final dynamic content;

  RoomEvent(this.name, this.owner, this.action,
      {this.card, this.content, this.src});

  RoomEvent.fromJson(Map json)
      : name = json['name'],
        owner = json['owner'],
        action = json['action'],
        card = json['card'],
        content = json['content'],
        src = json['src'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'owner': owner,
      'action': action,
      'card': card,
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
    if (length == 136) {
      randoms.add(banker!);
    }

    /// 自己的牌现排序
    for (var participantCard in participantCards) {
      participantCard.handSort();
    }

    take(banker!);

    return randoms;
  }

  /// 打牌
  bool send(int owner, String card) {
    if (owner != keeper) {
      return false;
    }
    participantCards[owner].send(card);
    sender = owner;
    sendCard = card;
    keeper = null;
    sendCheck(owner, card);

    return true;
  }

  /// pos的参与者打出一张牌，其他三家检查
  sendCheck(int owner, String card) {
    int nextPos = next(owner);
    ParticipantCard nextParticipant = participantCards[nextPos];
    int opponentPos = opponent(owner);
    ParticipantCard opponentParticipant = participantCards[opponentPos];
    int previousPos = previous(owner);
    ParticipantCard previousParticipant = participantCards[previousPos];

    CompleteType? nextCompleteType = nextParticipant.checkComplete(card);
    CompleteType? opponentCompleteType =
        opponentParticipant.checkComplete(card);
    CompleteType? previousCompleteType =
        previousParticipant.checkComplete(card);

    List<int>? results;
    int result = nextParticipant.checkBar(card);
    if (result == -1) {
      result = nextParticipant.checkTouch(card);
    }
    if (result == -1) {
      result = opponentParticipant.checkBar(card);
    }
    if (result == -1) {
      result = opponentParticipant.checkTouch(card);
    }
    if (result == -1) {
      result = previousParticipant.checkBar(card);
    }
    if (result == -1) {
      result = previousParticipant.checkTouch(card);
    }
    // if (result == -1) {
    //   results = nextParticipant.checkDrawing(card);
    // }

    /// 所有的参与者都无法响应，则发牌
    if (result == -1 &&
        results == null &&
        nextCompleteType == null &&
        opponentCompleteType == null &&
        previousCompleteType == null) {
      take(nextPos);
    } else {
      logger.i('some one can action');
    }
  }

  /// 杠牌发牌
  bool barTake(int owner) {
    if (unknownCards.isEmpty) {
      _round();

      return false;
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
    participantCards[owner].take(card, ComingCardType.bar);

    return true;
  }

  /// 发牌
  take(int owner) {
    if (unknownCards.isEmpty) {
      _round();

      return;
    }
    String card = unknownCards.removeLast();
    sender = null;
    sendCard = null;
    keeper = owner;
    if (unknownCards.length < 5) {
      participantCards[owner].take(card, ComingCardType.sea);
    } else {
      participantCards[owner].take(card, ComingCardType.self);
    }
  }

  /// 某个参与者过，没有采取任何行为
  bool pass(int owner) {
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
    ParticipantCard participant = participantCards[owner];
    participant.participantState.clear();
    int nextPos = next(owner);
    ParticipantCard nextParticipant = participantCards[nextPos];

    int opponentPos = opponent(owner);
    ParticipantCard opponentParticipant = participantCards[opponentPos];

    int previousPos = previous(owner);
    ParticipantCard previousParticipant = participantCards[previousPos];
    if (nextParticipant.participantState.isEmpty &&
        opponentParticipant.participantState.isEmpty &&
        previousParticipant.participantState.isEmpty) {
      take(next(sender!));
    }

    return true;
  }

  /// 某个参与者碰打出的牌
  bool touch(int owner, int pos) {
    if (sendCard == null) {
      return false;
    }
    bool result = participantCards[owner].touch(pos, card: sendCard!);
    if (participantCards[owner].touchCards.length == 4) {
      participantCards[owner].packer = sender;
    }
    participantCards[sender!].poolCards.removeLast();
    keeper = owner;
    sender = null;
    sendCard = null;

    return result;
  }

  /// 某个参与者杠打出的牌，pos表示可杠的手牌的位置
  /// 明杠牌，分三种情况 pos为-1，表示是摸牌可杠，否则表示手牌可杠的位置 返回值为杠的牌，为空表示未成功
  String? bar(int owner, int pos) {
    ParticipantCard participantCard = participantCards[owner];

    String? card = participantCard.bar(pos, sender: sender, card: sendCard);
    if (card == null) {
      return null;
    }
    if (sender != null) {
      participantCards[sender!].poolCards.removeLast();
      if (participantCards[owner].touchCards.length == 4) {
        participantCards[owner].packer = sender;
      }
    }
    bool canRob = false;
    for (int i = 0; i < participantCards.length; ++i) {
      if (owner != i) {
        ParticipantCard participantCard = participantCards[i];
        CompleteType? completeType = participantCard.checkComplete(card);
        if (completeType != null) {
          canRob = true;
          robber = owner;
          robCard = card;
        }
      }
    }
    if (!canRob) {
      keeper = owner;
      sender = null;
      sendCard = null;

      barTake(owner);

      return card;
    }

    return null;
  }

  /// 某个参与者暗杠，pos表示杠牌的位置
  darkBar(int owner, int pos) {
    String? card = participantCards[owner].darkBar(pos);
    if (card == null) {}
    barTake(owner);
  }

  /// 某个参与者吃打出的牌，pos表示吃牌的位置
  bool drawing(int owner, int pos) {
    if (sendCard == null) {
      return false;
    }
    bool result = participantCards[owner].drawing(pos, sendCard!);
    participantCards[sender!].poolCards.removeLast();
    keeper = owner;
    sender = null;
    sendCard = null;

    return result;
  }

  bool score(int owner, CompleteType completeType) {
    int? baseScore = completeTypeScores[completeType];
    if (baseScore == null) {
      return false;
    }
    ParticipantCard participantCard = participantCards[owner];
    if (robber != null && robCard != null) {
      participantCard.score.value += baseScore * 3;
      participantCards[robber!].score.value -= baseScore * 3;
    } else if (participantCard.comingCardType == ComingCardType.bar ||
        participantCard.comingCardType == ComingCardType.sea) {
      baseScore = baseScore * 2;
      participantCard.score.value += baseScore * 3;
    } else if (participantCard.comingCardType == ComingCardType.self) {
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
  CompleteType? complete(int owner) {
    CompleteType? completeType = participantCards[owner].complete();
    if (completeType != null) {
      score(owner, completeType);
      banker = owner;
    }

    return completeType;
  }

  /// 房间的事件有外部触发，所有订阅者都会触发监听事件，本方法由外部调用，比如外部的消息chatMessage
  onRoomEvent(RoomEvent roomEvent) async {
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
        break;
      case RoomEventAction.barTake:
        break;
      case RoomEventAction.seaTake:
        break;
      case RoomEventAction.send:
        break;
      case RoomEventAction.touch:
        break;
      case RoomEventAction.bar:
        break;
      case RoomEventAction.darkBar:
        break;
      case RoomEventAction.drawing:
        break;
      case RoomEventAction.complete:
        break;
      case RoomEventAction.pass:
        break;
      case RoomEventAction.rob:
        break;
      default:
        break;
    }
  }
}

class MajiangRoomPool {
  final Map<String, MajiangRoom> rooms = {};

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  Future<MajiangRoom> createRoom(String name, List<String> peerIds) async {
    MajiangRoom majiangRoom = MajiangRoom(name);
    await majiangRoom.init(peerIds);
    rooms[name] = majiangRoom;

    return majiangRoom;
  }

  MajiangRoom? get(String name) {
    return rooms[name];
  }

  /// 房间的事件有外部触发，所有订阅者都会触发监听事件，本方法由外部调用，比如外部的消息chatMessage
  onRoomEvent(RoomEvent roomEvent) async {
    String roomName = roomEvent.name;
    MajiangRoom? room = get(roomName);
    if (room == null) {
      return;
    }
    if (roomEvent.action == RoomEventAction.room) {
      List<String>? peerIds;
      String? content = roomEvent.content;
      if (content != null) {
        peerIds = JsonUtil.toJson(content);
      } else {
        peerIds = [];
      }
      createRoom(roomName, peerIds!);
    } else {
      room.onRoomEvent(roomEvent);
    }
  }
}

final MajiangRoomPool majiangRoomPool = MajiangRoomPool();
