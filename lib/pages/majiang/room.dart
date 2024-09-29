import 'dart:async';
import 'dart:math';

import 'package:colla_chat/pages/majiang/card.dart';
import 'package:colla_chat/pages/majiang/card_util.dart';
import 'package:colla_chat/pages/majiang/participant_card.dart';
import 'package:colla_chat/provider/myself.dart';
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

  /// 庄家
  int? banker;

  /// 当前的持有发牌的参与者
  int? keeper;

  /// 刚出牌的参与者
  int? sender;

  /// 正在等待做出决定的参与者，如果为空，则房间发牌，
  /// 如果都是pass消解等待的，则发牌，有一家是非pass消解的不发牌
  List<int> waiting = [];

  late final int current;

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  MajiangRoom(this.name, List<ParticipantCard> peers) {
    _init(peers);

    /// 房间池分发到房间的事件自己也需要监听
    roomEventStreamSubscription =
        roomEventStreamController.stream.listen((RoomEvent roomEvent) {
      onRoomEvent(roomEvent);
    });
  }

  /// 加参与者，第一个是自己，第二个是下家，第三个是对家，第四个是上家
  _init(List<ParticipantCard> peers) {
    /// 房间池分发到房间的事件每个参与者都需要监听
    for (int i = 0; i < peers.length; ++i) {
      var peer = peers[i];
      participantCards.add(ParticipantCard(peer.peerId,
          robot: peer.robot,
          roomEventStreamController: roomEventStreamController));
      if (myself.peerId == peer.peerId) {
        current = i;
      }
    }
    if (peers.length < 4) {
      for (int i = 0; i < 4 - peers.length; i++) {
        ParticipantCard participantCard = ParticipantCard('robot$i',
            robot: true, roomEventStreamController: roomEventStreamController);
        participantCards.add(participantCard);
      }
    }
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
      if (i < 53) {
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

    return randoms;
  }

  /// 打牌
  send(int owner, String card) {
    participantCards[owner].send(card);
    sender = owner;
    keeper = null;
    sendCheck(owner, card);
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
    if (result == -1) {
      results = nextParticipant.checkDrawing(card);
    }

    /// 所有的参与者都无法响应，则发牌
    if (result == -1 &&
        results == null &&
        nextCompleteType == null &&
        opponentCompleteType == null &&
        previousCompleteType == null) {
      take(nextPos);
    }
  }

  /// 发牌
  take(int owner) {
    String card = unknownCards.removeLast();
    participantCards[owner].take(card);
    keeper = owner;
  }

  /// 某个参与者过，没有采取任何行为
  pass(int owner) {
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
  }

  /// 某个参与者碰
  touch(int owner, String card) {
    participantCards[owner].touch(card);
  }

  /// 某个参与者杠
  bar(int owner, String card) {
    participantCards[owner].bar(card);
  }

  /// 某个参与者暗杠
  darkBar(int owner, String card) {
    participantCards[owner].darkBar(card);
  }

  /// 某个参与者吃
  drawing(int owner, String card) {
    participantCards[owner].drawing(card);
  }

  /// 某个参与者胡牌
  complete(int owner) {
    participantCards[owner].complete();
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

  MajiangRoom createRoom(String name, List<ParticipantCard> peers) {
    MajiangRoom majiangRoom = MajiangRoom(name, peers);
    rooms[name] = majiangRoom;

    return majiangRoom;
  }

  MajiangRoom? get(String name) {
    return rooms[name];
  }

  /// 房间的事件有外部触发，所有订阅者都会触发监听事件，本方法由外部调用，比如外部的消息chatMessage
  onRoomEvent(RoomEvent roomEvent) {
    if (roomEvent.action == RoomEventAction.create) {
      String name = roomEvent.name;
      dynamic content = roomEvent.content;
      List<ParticipantCard> peers = JsonUtil.toJson(content);
      createRoom(name, peers);
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
