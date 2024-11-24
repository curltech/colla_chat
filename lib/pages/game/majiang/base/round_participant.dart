import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/outstanding_action.dart';
import 'package:colla_chat/pages/game/majiang/base/participant.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';
import 'package:colla_chat/pages/game/majiang/base/waste_pile.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:get/get.dart';

/// 每一轮的参与者
class RoundParticipant {
  /// ParticipantDirection.index
  int index;

  final Participant participant;

  final Round round;

  //积分
  final RxInt score = 0.obs;

  // 手牌
  final HandPile handPile = HandPile();

  //打出的牌
  final WastePile wastePile = WastePile();

  /// 参与者等待处理的行为
  final RxMap<OutstandingAction, List<int>> outstandingActions =
      RxMap<OutstandingAction, List<int>>({});

  /// 参与者已经发生的行为，比如，明杠，暗杠等，值数组代表行为的发生人
  /// 自己代表自摸杠，别人代表打牌杠
  final Map<OutstandingAction, List<int>> earnedActions =
      <OutstandingAction, List<int>>{};

  /// 记录重要的事件
  final List<RoomEvent> roomEvents = [];

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  /// 包了自己的胡牌的人
  int? packer;

  RoundParticipant(this.index, this.round, this.participant);

  ParticipantDirection get direction {
    return NumberUtil.toEnum(ParticipantDirection.values, index)!;
  }

  clear() {
    outstandingActions.clear();
    earnedActions.clear();
    packer = null;
  }

  addOutstandingAction(OutstandingAction outstandingAction, List<int> vs) {
    List<int>? values = outstandingActions[outstandingAction];
    if (values == null) {
      values = [];
      outstandingActions[outstandingAction] = values;
    }
    values.addAll(vs);
  }

  addEarnedAction(OutstandingAction outstandingAction, List<int> vs) {
    List<int>? values = earnedActions[outstandingAction];
    if (values == null) {
      values = [];
      earnedActions[outstandingAction] = values;
    }
    values.addAll(vs);
  }

  /// 打牌，owner打出牌card，对其他人检查打的牌是否能够胡牌，杠牌和碰牌，返回检查的结果
  Map<OutstandingAction, List<int>>? _send(int owner, Card card) {
    if (owner == index) {
      handPile.send(card);
      wastePile.cards.add(card);

      return null;
    } else {
      /// 不是owner，检查是否可以胡牌，碰牌或者杠牌
      Map<OutstandingAction, List<int>> outstandingActions = _check(card: card);
      if (outstandingActions.isNotEmpty) {
        return outstandingActions;
      }
    }

    return null;
  }

  /// 检查行为状态，既包括摸牌检查，也包含打牌检查
  Map<OutstandingAction, List<int>> _check({Card? card}) {
    outstandingActions.clear();
    CompleteType? completeType = handPile.checkComplete(card: card);
    if (completeType != null) {
      addOutstandingAction(OutstandingAction.complete, [completeType.index]);
    }
    if (card == handPile.takeCard) {
      List<int>? pos = handPile.checkDarkBar();
      if (pos != null) {
        addOutstandingAction(OutstandingAction.darkBar, pos);
      }
      pos = handPile.checkTakeBar();
      if (pos != null) {
        addOutstandingAction(OutstandingAction.bar, pos);
      }
    } else if (card != null) {
      int? pos = handPile.checkSendBar(card);
      if (pos != null) {
        addOutstandingAction(OutstandingAction.bar, [pos]);
      }
      pos = handPile.checkTouch(card);
      if (pos != null) {
        addOutstandingAction(OutstandingAction.touch, [pos]);
      }
    }

    if (outstandingActions.value.isNotEmpty) {
      roomController.majiangFlameGame.loadActionArea();
    }

    return outstandingActions.value;
  }

  /// 碰牌,owner碰pos位置，sender打出的card牌
  bool _touch(int owner, int pos, int sender, Card card) {
    if (index == owner) {
      return handPile.touch(pos, card);
    }

    return true;
  }

  /// 杠牌，分成打牌杠牌sendBar和摸牌杠牌takeBar
  /// card和sender不为空，则是_sendBar
  /// 否则是_takeBar
  Card? _bar(int owner, int pos, {Card? card, int? sender}) {
    if (index == owner) {
      if (sender != null) {
        return _sendBar(owner, pos, card!, sender);
      } else {
        return _takeBar(owner, pos);
      }
    }

    return null;
  }

  /// 打牌杠牌，分成打牌杠牌sendBar和摸牌杠牌takeBar
  Card? _sendBar(int owner, int pos, Card card, int sender) {
    if (index == owner) {
      Card? c = handPile.sendBar(pos, card, sender);
      if (c != null) {
        addEarnedAction(OutstandingAction.bar, [sender, sender, sender]);
      }

      return c;
    }

    return null;
  }

  /// owner明杠位置pos的牌，分两种情况，摸牌杠牌和打牌杠牌
  /// 打牌杠牌的时候sender不为空，表示打牌的参与者
  /// pos表示杠牌的位置,如果摸牌杠牌的时候为手牌杠牌的位置，打牌杠牌的时候是杠牌的位置
  /// 返回值为杠的牌，为空表示未成功
  Card? _takeBar(int owner, int pos) {
    if (index == owner) {
      Card? card = handPile.takeBar(pos, owner);
      if (card != null) {
        addEarnedAction(OutstandingAction.bar, [owner]);
      }

      return card;
    }

    return null;
  }

  /// 暗杠牌，owner杠手上pos位置已有的四张牌（card==null）或者新进的card（card!=null）
  Card? _darkBar(int owner, int pos) {
    if (index == owner) {
      Card? card = handPile.darkBar(pos, owner);
      if (card != null) {
        addEarnedAction(OutstandingAction.bar, [owner, owner]);
      }

      return card;
    }

    return null;
  }

  /// 吃牌，owner在pos位置吃上家的牌card
  Card? _drawing(int owner, int pos, Card card) {
    if (index == owner) {
      Card? c = handPile.drawing(pos, card);

      return c;
    }

    return null;
  }

  CompleteType? _checkComplete(int owner, Card card) {
    if (index == owner) {
      return handPile.checkComplete(card: card);
    }

    return null;
  }

  /// 胡牌，owner胡participantState中的可胡的牌形,pos表示可胡牌形数组的位置
  CompleteType? _complete(int owner, int complete) {
    if (index == owner) {
      List<int>? completes = outstandingActions[OutstandingAction.complete];
      if (completes != null && completes.isNotEmpty) {
        CompleteType? completeType =
            NumberUtil.toEnum(CompleteType.values, complete);
        if (completeType != null) {
          logger.i('complete:$completeType');
        }

        return completeType;
      }
    }

    return null;
  }

  /// 过牌，owner宣布不做任何操作
  _pass(int owner) {
    if (index == owner) {
      outstandingActions.clear();
    }
  }

  /// 摸牌，有三种摸牌，普通的自摸，海底捞的自摸，杠上自摸
  /// owner摸到card牌，takeCardType表示摸牌的方式
  Map<OutstandingAction, List<int>>? _take(
      int owner, Card card, int takeCardTypeIndex) {
    TakeCardType? takeCardType =
        NumberUtil.toEnum(TakeCardType.values, takeCardTypeIndex);
    if (takeCardType == null) {
      return null;
    }
    if (index == owner) {
      handPile.takeCard = card;
      handPile.takeCardType = takeCardType;

      /// 检查摸到的牌，看需要采取的动作，这里其实只需要摸牌检查
      Map<OutstandingAction, List<int>> outstandingActions = _check(card: card);
      if (outstandingActions.isNotEmpty) {
        roomController.majiangFlameGame.loadActionArea();
      }

      return outstandingActions;
    }

    return null;
  }

  /// 抢杠胡牌，owner抢src的明杠牌card胡牌
  CompleteType? _rob(int owner, int pos, Card card, int src) {
    if (index == owner) {
      List<int>? completes = outstandingActions[OutstandingAction.complete];
      if (completes != null && completes.isNotEmpty) {
        int complete = completes[pos];
        CompleteType? completeType =
            NumberUtil.toEnum(CompleteType.values, complete);
        if (completeType != null) {
          logger.i('complete:$completeType');
        }

        return completeType;
      }
    }

    return null;
  }

  /// 分发房间来的事件，处理各参与者该自己处理的部分
  dynamic onRoomEvent(RoomEvent roomEvent) {
    switch (roomEvent.action) {
      case RoomEventAction.take:
        if (TakeCardType.self.index == roomEvent.pos) {
          return _take(roomEvent.owner, roomEvent.card!, roomEvent.pos!);
        }
        break;
      case RoomEventAction.barTake:
        if (TakeCardType.bar.index == roomEvent.pos) {
          return _take(roomEvent.owner, roomEvent.card!, roomEvent.pos!);
        }
        break;
      case RoomEventAction.seaTake:
        if (TakeCardType.sea.index == roomEvent.pos) {
          return _take(roomEvent.owner, roomEvent.card!, roomEvent.pos!);
        }
        break;
      case RoomEventAction.send:
        return _send(roomEvent.owner, roomEvent.card!);
      case RoomEventAction.touch:
        return _touch(
            roomEvent.owner, roomEvent.pos!, roomEvent.src!, roomEvent.card!);
      case RoomEventAction.bar:
        return _bar(roomEvent.owner, roomEvent.pos!,
            card: roomEvent.card, sender: roomEvent.src);
      case RoomEventAction.sendBar:
        return _sendBar(
            roomEvent.owner, roomEvent.pos!, roomEvent.card!, roomEvent.src!);
      case RoomEventAction.takeBar:
        return _takeBar(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.darkBar:
        return _darkBar(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.drawing:
        return _drawing(roomEvent.owner, roomEvent.pos!, roomEvent.card!);
      case RoomEventAction.check:
        return _check(card: roomEvent.card);
      case RoomEventAction.checkComplete:
        return _checkComplete(roomEvent.owner, roomEvent.card!);
      case RoomEventAction.complete:
        return _complete(roomEvent.owner, roomEvent.pos!);
      case RoomEventAction.pass:
        return _pass(roomEvent.owner);
      case RoomEventAction.rob:
        return _rob(
            roomEvent.owner, roomEvent.pos!, roomEvent.card!, roomEvent.src!);
      default:
        break;
    }
  }
}
