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

enum RoomEventAction {
  create, //新房间
  play, //新局
  take, //发牌
  send, //打牌
  touch, //碰牌
  bar, //杠牌
  darkBar, //暗杠
  drawing, //吃
  complete, //胡
}

class RoomEvent {
  /// 房间的名称
  final String name;

  /// 事件的拥有者，-1表示房间或者系统，0，1，2，3表示参与者的位置
  final int owner;

  /// 每个事件的内容不同，
  /// 新房间事件是一个参与者数组
  /// 新局事件是庄家的位置和一个随机数的数组，代表发牌
  /// 其他的事件都是参与者的事件，表示牌
  final dynamic content;

  /// RoomAction事件的枚举
  final RoomEventAction action;

  RoomEvent(this.name, this.owner, this.content, this.action);
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
    CompleteType.pureOneType: 150,
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

  /// 正在等待做出决定的参与者，如果为空，则房间发牌，
  /// 如果都是pass消解等待的，则发牌，有一家是非pass消解的不发牌
  List<int> waiting = [];

  late final int current;

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  MajiangRoom(this.name);

  /// 加参与者，第一个是自己，第二个是下家，第三个是对家，第四个是上家
  init(List<ParticipantCard> peers) async {
    /// 房间池分发到房间的事件每个参与者都需要监听
    for (int i = 0; i < peers.length; ++i) {
      var peer = peers[i];
      if (myself.peerId == peer.peerId) {
        current = i;
      }
      Linkman? linkman =
          await linkmanService.findCachedOneByPeerId(peer.peerId);
      ParticipantCard participantCard = ParticipantCard(peer.peerId, peer.name,
          robot: peer.robot,
          roomEventStreamController: roomEventStreamController);
      participantCard.avatarWidget =
          linkman == null ? AppImage.mdAppImage : linkman.avatarImage;
      participantCard.avatarWidget ??= AppImage.mdAppImage;
      participantCards.add(participantCard);
    }
    if (peers.length < 4) {
      for (int i = 0; i < 4 - peers.length; i++) {
        ParticipantCard participantCard = ParticipantCard(
            'robot$i', '${AppLocalizations.t('robot')}$i',
            robot: true, roomEventStreamController: roomEventStreamController);
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
  List<int> play({List<int>? randoms}) {
    for (var participantCard in participantCards) {
      participantCard.clear();
    }
    unknownCards.clear();
    banker = null;
    keeper = null;
    sendCard = null;
    sender = null;
    barCount = 0;
    List<String> allCards = [...cardConcept.allCards];
    Random random = Random.secure();
    randoms ??= [];
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
        int reminder = i % 4;
        participantCards[reminder].handCards.add(card);
      } else {
        unknownCards.add(card);
      }
    }

    /// 自己的牌现排序
    for (var participantCard in participantCards) {
      participantCard.handSort();
    }

    /// 如果没有指定庄家，开新局的参与者就是庄家，否则设定庄家
    int length = randoms.length;
    if (length == 137) {
      banker = randoms[136];
      keeper = banker;
    } else {
      int pos = 0;
      banker = pos;
      keeper = banker;
      randoms.add(pos);
    }

    take(0);

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
      logger.e('error');
    }
  }

  /// 杠牌次数
  int barCount = 0;

  /// 杠牌发牌
  barTake(int owner) {
    if (unknownCards.isEmpty) {
      play();

      return;
    }
    int mod = barCount ~/ 2;
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
  }

  /// 发牌
  take(int owner) {
    if (unknownCards.isEmpty) {
      play();

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
    participantCards[sender!].poolCards.removeLast();
    keeper = owner;
    sender = null;
    sendCard = null;

    return result;
  }

  /// 某个参与者杠打出的牌
  bool bar(int owner, int pos) {
    if (sendCard == null) {
      return false;
    }
    bool result = participantCards[owner].bar(pos, card: sendCard!);
    participantCards[sender!].poolCards.removeLast();
    keeper = owner;
    barCount++;
    sender = null;
    sendCard = null;
    barTake(owner);

    return result;
  }

  /// 某个参与者暗杠，pos表示杠牌的位置
  darkBar(int owner, int pos) {
    participantCards[owner].darkBar(pos);
    barCount++;
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
    if (participantCard.comingCardType == ComingCardType.bar ||
        participantCard.comingCardType == ComingCardType.sea) {
      baseScore = baseScore * 2;
      participantCard.score.value += baseScore * 3;
    } else if (participantCard.comingCardType == ComingCardType.self) {
      participantCard.score.value += baseScore * 3;
    }
    if (sender != null) {
      participantCards[sender!].score.value -= baseScore;
    } else {
      for (int i = 0; i < participantCards.length; ++i) {
        ParticipantCard participantCard = participantCards[i];
        if (i == sender) {
          participantCard.score.value -= baseScore;
        }
      }
    }

    return true;
  }

  /// 某个参与者胡牌
  CompleteType? complete(int owner) {
    CompleteType? completeType = participantCards[owner].complete();
    if (completeType != null) {
      score(owner, completeType);
      play();
    }

    return completeType;
  }

  void onRoomEvent(RoomEvent roomEvent) {
    if (roomEvent.action == RoomEventAction.play) {
      dynamic content = roomEvent.content;
      List<int>? randoms = JsonUtil.toJson(content);
      play(randoms: randoms);
    }
  }
}

class MajiangRoomPool {
  final Map<String, MajiangRoom> rooms = {};

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  Future<MajiangRoom> createRoom(
      String name, List<ParticipantCard> peers) async {
    MajiangRoom majiangRoom = MajiangRoom(name);
    await majiangRoom.init(peers);
    rooms[name] = majiangRoom;

    return majiangRoom;
  }

  MajiangRoom? get(String name) {
    return rooms[name];
  }

  /// 房间的事件有外部触发，所有订阅者都会触发监听事件，本方法由外部调用，比如外部的消息chatMessage
  onRoomEvent(RoomEvent roomEvent) async {
    if (roomEvent.action == RoomEventAction.create) {
      String name = roomEvent.name;
      dynamic content = roomEvent.content;
      List<ParticipantCard> peers = JsonUtil.toJson(content);
      await createRoom(name, peers);
    } else {
      String name = roomEvent.name;
      MajiangRoom? majiangRoom = get(name);
      if (majiangRoom != null) {
        majiangRoom.roomEventStreamController.add(roomEvent);
      }
    }
  }
}

final MajiangRoomPool majiangRoomPool = MajiangRoomPool();
