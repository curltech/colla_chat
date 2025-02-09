import 'dart:async';
import 'dart:ui';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/mahjong/base/hand_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_event.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_pool.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/suit.dart';
import 'package:colla_chat/pages/game/mahjong/base/tile.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';



/// 麻将房间，包含一副麻将
class Room {
  final String name;

  /// 房间的创建者
  late final int creator;

  /// 四个参与者
  late final List<Participant> participants;

  /// 每个房间都有多轮
  final List<Round> rounds = [];

  /// 当前轮
  int? currentRoundIndex;

  /// 当前的庄家，在每一轮胡牌后设置胡牌的人为新的庄家
  /// 如果没有人胡牌则庄家不变
  late int banker;

  late int currentParticipant;

  /// 胡牌的分数
  Map<WinType, int> completeTypeScores = {
    WinType.thirteenOne: 300,
    WinType.oneNine: 150,
    WinType.pureTouch: 150,
    WinType.luxPair7: 150,
    WinType.pureOneType: 100,
    WinType.mixTouch: 100,
    WinType.pair7: 80,
    WinType.mixOneType: 60,
    WinType.touch: 40,
    WinType.small: 10,
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
        creator = json['creator'],
        currentParticipant = json['currentParticipant'],
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
      'creator': creator,
      'currentParticipant': currentParticipant,
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
        creator = i;
        currentParticipant = i;
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
        }
      }
      participant.sprite = Sprite(image);
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
  /// 由creator调用，然后向其他参与者发送chatMessage
  Future<Round> _createRound(int banker) async {
    Round round = Round(rounds.length, this, banker);
    rounds.add(round);
    currentRoundIndex = round.id;

    return round;
  }

  /// 发起房间的事件，由发起事件的参与者调用
  /// 完成后把round事件分发到其他参与者
  Future<dynamic> startRoomEvent(RoomEvent roomEvent) async {
    dynamic returnValue;
    if (roomEvent.action == RoomEventAction.round) {
      Round round = await _createRound(roomEvent.owner);
      returnValue = round;
      for (int i = 0; i < round.roundParticipants.length; i++) {
        RoundParticipant roundParticipant = round.roundParticipants[i];
        if (i != creator) {
          String content = JsonUtil.toJsonString(roundParticipant.handPile);
          roomEvent = RoomEvent(name,
              roundId: round.id,
              owner: roomEvent.owner,
              sender: creator,
              receiver: i,
              action: RoomEventAction.round,
              content: content);
          ChatMessage chatMessage = await chatMessageService.buildChatMessage(
              receiverPeerId: roundParticipant.participant.peerId,
              subMessageType: ChatMessageSubType.mahjong,
              content: roomEvent);
          if (roundParticipant.participant.robot) {
            roomPool.onRoomEvent(chatMessage);
          } else {
            roomPool.send(chatMessage);
          }
        }
      }

      /// 第一张发牌给banker
      Tile? tile = await round.deal();
      if (tile != null) {
        // logger.w('first deal tile:${tile.toString()} to $banker');
      }
    } else {
      int? roundId = roomEvent.roundId;
      Round? round;
      if (roundId != null) {
        round = rounds[roundId];
      }
      if (round == null) {
        return null;
      }
      returnValue = await round.startRoomEvent(roomEvent);
    }

    return returnValue;
  }

  /// 房间的事件
  /// 直接调用round的事件处理器，不会进行事件分发到其他参与者
  Future<dynamic> onRoomEvent(RoomEvent roomEvent) async {
    // logger.w('room:$name has received event:${roomEvent.toString()}');
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
        mahjongFlameGame.reload();
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
