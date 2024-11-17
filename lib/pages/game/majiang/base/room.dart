import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/full_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/participant.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';
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
  takeBar,
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

  final int? roundId;

  /// 事件的拥有者，-1表示房间或者系统，0，1，2，3表示参与者的位置
  final int owner;

  /// RoomAction事件的枚举
  final RoomEventAction action;

  final Card? card;

  /// 行为发生的来源参与者，比如0胡了1打出的牌
  final int? src;

  final int? pos;

  /// 每个事件的内容不同，
  /// 新房间事件是一个参与者数组
  /// 新局事件是庄家的位置和一个随机数的数组，代表发牌
  /// 其他的事件都是参与者的事件，表示牌
  final dynamic content;

  RoomEvent(this.name, this.roundId, this.owner, this.action,
      {this.card, this.pos, this.content, this.src});

  RoomEvent.fromJson(Map json)
      : name = json['name'],
        roundId = json['roundId'],
        owner = json['owner'],
        action = json['action'],
        card = json['card'] != null ? fullPile[json['card']] : null,
        pos = json['pos'],
        content = json['content'],
        src = json['src'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'roundId': roundId,
      'owner': owner,
      'action': action,
      'card': card?.toString(),
      'pos': pos,
      'content': content,
      'src': src,
    };
  }
}

/// 麻将房间，包含一副麻将
class Room {
  final String name;

  /// 四个参与者
  final List<Participant> participants = [];

  /// 每个房间都有多轮
  final List<Round> rounds = [];

  /// 当前轮
  int? currentRound;

  /// 游戏的当前参与者视角
  int? currentParticipant;

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

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  Room(this.name);

  /// 加参与者，第一个是自己，第二个是下家，第三个是对家，第四个是上家
  Future<void> init(List<String> peerIds) async {
    for (int i = 0; i < peerIds.length; ++i) {
      String peerId = peerIds[i];
      if (myself.peerId == peerId) {
        currentParticipant = i;
      }
      Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
      String linkmanName =
          linkman == null ? AppLocalizations.t('unknown') : linkman.name;
      Participant participant = Participant(peerId, linkmanName, room: this);
      participant.avatarWidget =
          linkman == null ? AppImage.mdAppImage : linkman.avatarImage;
      participant.avatarWidget ??= AppImage.mdAppImage;
      participants.add(participant);
    }
    if (peerIds.length < 4) {
      for (int i = peerIds.length; i < 4; i++) {
        Participant participant = Participant(
          'robot$i',
          '${AppLocalizations.t('robot')}$i',
          room: this,
          robot: true,
        );
        participant.avatarWidget ??= AppImage.mdAppImage;
        participants.add(participant);
      }
    }

    /// 房间池分发到房间的事件自己也需要监听
    roomEventStreamSubscription =
        roomEventStreamController.stream.listen((RoomEvent roomEvent) {
      onRoomEvent(roomEvent);
    });
  }

  int? get(String peerId) {
    for (int i = 0; i < participants.length; i++) {
      Participant participant = participants[i];
      if (participant.peerId == peerId) {
        return i;
      }
    }
    return null;
  }

  /// 下家
  int next(int pos) {
    if (pos == participants.length - 1) {
      return 0;
    }
    return pos + 1;
  }

  /// 上家
  int previous(int pos) {
    if (pos == 0) {
      return participants.length - 1;
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
  createRound({List<int>? randoms}) {
    Round round = Round(rounds.length, this);
    rounds.add(round);
    currentRound = round.id;
  }

  /// 房间的事件有外部触发，所有订阅者都会触发监听事件，本方法由外部调用，比如外部的消息chatMessage
  dynamic onRoomEvent(RoomEvent roomEvent) async {
    int? roundId = roomEvent.roundId;
    Round? round;
    if (roundId != null) {
      round = rounds[roundId];
    }
    if (roomEvent.action == RoomEventAction.room) {
    } else if (roomEvent.action == RoomEventAction.room) {
      List<int>? randoms;
      String? content = roomEvent.content;
      if (content != null) {
        randoms = JsonUtil.toJson(content);
      }
      createRound(randoms: randoms);
    } else {
      round?.onRoomEvent(roomEvent);
    }
  }
}
