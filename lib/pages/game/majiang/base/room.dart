import 'dart:async';
import 'dart:ui';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/full_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/participant.dart';
import 'package:colla_chat/pages/game/majiang/base/room_pool.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/base/round_participant.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

/// 参与者的方位，房间创建时候固定的方位，用于获取牌的数据
/// east表示参与者数组的index为0，以此类推
enum ParticipantDirection { east, south, west, north }

/// 显示的角度，用于牌的显示方式
/// self表示自己，隐藏手牌会显示在屏幕上
/// 其他的代表next下家，opponent对家和previous上家，隐藏手牌手牌不会显示在屏幕上，只有碰杠牌财显示
enum AreaDirection { self, next, opponent, previous }

enum RoomEventAction {
  room, //新房间
  round, //新局
  take, //发牌
  barTake, //杠上发牌
  send, //打牌
  touch, //碰牌
  bar, //杠牌：包括sendBar和takeBar
  sendBar, //打牌杠牌
  takeBar, //摸牌杠牌和手牌杠牌
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
  final RoomEventAction? action;

  final Card? card;

  /// 行为发生的来源参与者，比如0胡了1打出的牌
  final int? src;

  /// 事件指定的牌的位置
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
        action = json['action'] != null
            ? StringUtil.enumFromString(RoomEventAction.values, json['action'])
            : null,
        card = json['card'] != null ? fullPile[json['card']] : null,
        pos = json['pos'],
        content = json['content'],
        src = json['src'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'roundId': roundId,
      'owner': owner,
      'action': action?.name,
      'card': card?.toString(),
      'pos': pos,
      'content': content,
      'src': src,
    };
  }

  @override
  String toString() {
    return 'name:$name,roundId:$roundId,owner:$owner,action:${action?.name},card:$card,pos:$pos,src:$src,content:$content';
  }
}

/// 麻将房间，包含一副麻将
class Room {
  final String name;

  /// 四个参与者
  late final List<Participant> participants;

  /// 每个房间都有多轮
  final List<Round> rounds = [];

  /// 当前轮
  int? currentRoundIndex;

  /// 当前的庄家，在每一轮胡牌后设置胡牌的人为新的庄家
  /// 如果没有人胡牌则庄家不变
  late int banker;

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

  Room(this.name, {required List<String> peerIds}) {
    participants = [];
    _init(peerIds);
  }

  Room.fromJson(Map json)
      : name = json['name'],
        banker = json['banker'] {
    participants = [];
    if (json['participants'] != null && json['participants'] is List) {
      for (var participant in json['participants']) {
        participants.add(Participant.fromJson(participant));
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'banker': banker,
      'participants': JsonUtil.toJson(participants),
    };
  }

  /// 加参与者
  Future<void> _init(List<String> peerIds) async {
    if (!peerIds.contains(myself.peerId)) {
      logger.e('Participant has no myself');
      throw 'Init room failure, participant has no myself';
    }
    for (int i = 0; i < peerIds.length; ++i) {
      String peerId = peerIds[i];
      Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
      String linkmanName = AppLocalizations.t('unknown');
      if (linkman != null) {
        linkmanName = linkman.name;
      }
      Participant participant = Participant(peerId, linkmanName, room: this);
      participants.add(participant);
      if (myself.peerId == participant.peerId) {
        banker = i;
      }
    }
    if (peerIds.length < 4) {
      for (int i = peerIds.length; i < 4; i++) {
        Participant participant = Participant(
          'robot$i',
          '${AppLocalizations.t('robot')}$i',
          room: this,
          robot: true,
        );
        participants.add(participant);
      }
    }

    /// 房间池分发到房间的事件自己也需要监听
    roomEventStreamSubscription =
        roomEventStreamController.stream.listen((RoomEvent roomEvent) {
      onRoomEvent(roomEvent);
    });
  }

  /// 初始化参与者，设置名称，头像
  Future<void> init() async {
    Image defaultImage = await Flame.images.load('app.png');
    for (int i = 0; i < participants.length; ++i) {
      Participant participant = participants[i];
      participant.room = this;
      if (myself.peerId == participant.peerId) {
        roomController.selfParticipantDirection.value =
            NumberUtil.toEnum(ParticipantDirection.values, i)!;
      }
      Linkman? linkman =
          await linkmanService.findCachedOneByPeerId(participant.peerId);
      Image image = defaultImage;
      if (linkman != null) {
        if (linkman.avatar != null) {
          image =
              await Flame.images.fromBase64('linkmanName.png', linkman.avatar!);
          participant.sprite = Sprite(image);
        }
      }
    }
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
    if (pos == 3) {
      return 0;
    }
    return pos + 1;
  }

  /// 上家
  int previous(int pos) {
    if (pos == 0) {
      return 3;
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
    throw 'error direction';
  }

  Round? get currentRound {
    if (currentRoundIndex != null) {
      return rounds[currentRoundIndex!];
    }

    return null;
  }

  /// 新玩一局
  /// 由庄家调用，然后向其他参与者发送chatMessage
  Future<Round> _createRound(int banker) async {
    Round round = Round(rounds.length, this, banker);
    rounds.add(round);
    currentRoundIndex = round.id;

    return round;
  }

  /// 发起房间的事件，由发起事件的参与者调用
  /// 完成后把事件分发到其他参与者
  dynamic startRoomEvent(RoomEvent roomEvent) async {
    dynamic returnValue;
    Round? round;
    if (roomEvent.action == RoomEventAction.round) {
      round = await _createRound(roomEvent.owner);

      return round;
    }
    int? roundId = roomEvent.roundId;
    if (roundId != null) {
      round = rounds[roundId];
    }
    if (round == null) {
      return null;
    }
    returnValue = await round.onRoomEvent(roomEvent);
    for (int i = 0; i < round.roundParticipants.length; i++) {
      RoundParticipant roundParticipant = round.roundParticipants[i];
      if (roundParticipant.participant.peerId != myself.peerId) {
        String content = JsonUtil.toJsonString(roundParticipant.handPile);
        RoomEvent roomEvent = RoomEvent(
            name, round.id, i, RoomEventAction.round,
            content: content);
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

  /// 房间的事件
  /// 直接调用round的事件处理器，不会进行事件分发到其他参与者
  dynamic onRoomEvent(RoomEvent roomEvent) async {
    logger.w('room:$name has received event:${roomEvent.toString()}');
    dynamic returnValue;
    if (roomEvent.action == RoomEventAction.round) {
      String? content = roomEvent.content;
      if (content != null) {
        var json = JsonUtil.toJson(content);
        HandPile handPile = HandPile.fromJson(json);
        Round round = Round(roomEvent.roundId!, this, banker,
            owner: roomEvent.owner, handPile: handPile);
        if (round.id >= rounds.length) {
          rounds.add(round);
        }
        currentRoundIndex = round.id;
        returnValue = round;
        roomController.majiangFlameGame.reload();
      }
    } else {
      int? roundId = roomEvent.roundId;
      Round? round;
      if (roundId != null) {
        round = rounds[roundId];
      }
      returnValue = await round?.onRoomEvent(roomEvent);
    }

    return returnValue;
  }
}
