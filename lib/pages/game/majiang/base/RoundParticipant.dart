import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/participant.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/base/suit.dart';
import 'package:colla_chat/pages/game/majiang/base/waste_pile.dart';
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

  /// 记录重要的事件
  final List<RoomEvent> roomEvents = [];

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  /// 杠牌次数
  int barCount = 0;

  /// 别人给自己杠牌的人
  List<int> barSenders = [];

  /// 包了自己的胡牌的人
  int? packer;

  RoundParticipant(this.index, this.round, this.participant);

  ParticipantDirection get direction {
    return NumberUtil.toEnum(ParticipantDirection.values, index)!;
  }

  clear() {
    outstandingActions.clear();
    barCount = 0;
    barSenders.clear();
    packer = null;
  }

  addOutstandingAction(OutstandingAction outstandingAction, int value) {
    List<int>? values = outstandingActions[outstandingAction];
    if (values == null) {
      values = [];
      outstandingActions[outstandingAction] = values;
    }
    values.add(value);
  }

  /// 打牌，owner打出牌card，对其他人检查打的牌是否能够胡牌，杠牌和碰牌，返回检查的结果
  int? _send(int owner, Card card) {
    if (owner == index) {
      handPile.send(card);
      wastePile.cards.add(card);

      return null;
    } else {
      /// 不是owner，检查是否可以胡牌，碰牌或者杠牌
      CompleteType? completeType = handPile.checkComplete(card);
      int? pos = handPile.checkBar(card);
      pos ??= handPile.checkTouch(card);
      if (completeType != null) {
        return completeType.index;
      }
      if (pos != null) {
        return pos;
      }
    }

    return null;
  }

  Map<OutstandingAction, List<int>> _check(int owner, Card card) {
    handPile.checkComplete(card);
    handPile.checkBar(card);
    handPile.checkTouch(card);

    return outstandingActions;
  }

  /// 碰牌,owner碰pos位置，sender打出的card牌
  bool _touch(int owner, int pos, int sender, Card card) {
    if (index == owner) {
      handPile.touch(pos, card);
    } else {
      if (wastePile.cards.last == card) {
        wastePile.cards.removeLast();
      } else {
        return false;
      }
    }

    return true;
  }

  Card? _bar(int owner, int pos, Card card, int sender) {
    if (index == owner) {
      return handPile.bar(pos, card, sender);
    }

    return null;
  }

  /// owner明杠位置pos的牌，分两种情况，摸牌杠牌和打牌杠牌
  /// 打牌杠牌的时候sender不为空，表示打牌的参与者
  /// pos表示杠牌的位置,如果摸牌杠牌的时候为手牌杠牌的位置，打牌杠牌的时候是杠牌的位置
  /// 返回值为杠的牌，为空表示未成功
  Card? _takeBar(int owner, int pos, Card card) {
    if (index == owner) {
      return handPile.takeBar(pos, card, owner);
    }

    return null;
  }

  /// 暗杠牌，owner杠手上pos位置已有的四张牌（card==null）或者新进的card（card!=null）
  Card? _darkBar(int owner, int pos) {
    if (index == owner) {
      Card? card = handPile.darkBar(pos, owner);

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
      return handPile.checkComplete(card);
    }

    return null;
  }

  /// 胡牌，owner胡participantState中的可胡的牌形,pos表示可胡牌形数组的位置
  CompleteType? _complete(int owner, int pos) {
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

  /// 过牌，owner宣布不做任何操作
  _pass(int owner) {
    if (index == owner) {
      outstandingActions.clear();
    }
  }

  /// 摸牌，有三种摸牌，普通的自摸，海底捞的自摸，杠上自摸
  /// owner摸到card牌，takeCardType表示摸牌的方式
  List<int>? _take(int owner, Card card, int pos) {
    TakeCardType? takeCardType = NumberUtil.toEnum(TakeCardType.values, pos);
    if (takeCardType == null) {
      return null;
    }
    if (index == owner) {
      handPile.takeCard = card;
      handPile.takeCardType = takeCardType;

      /// 检查摸到的牌，看需要采取的动作
      CompleteType? completeType = handPile.checkComplete(card);
      List<int>? pos = handPile.checkDarkBar();
      pos ??= handPile.checkTakeBar();
      if (completeType != null) {
        return [completeType.index];
      }
      if (pos != null) {
        return pos;
      }
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
          _take(roomEvent.owner, roomEvent.card!, roomEvent.pos!);
        }
        break;
      case RoomEventAction.barTake:
        if (TakeCardType.bar.index == roomEvent.pos) {
          _take(roomEvent.owner, roomEvent.card!, roomEvent.pos!);
        }
        break;
      case RoomEventAction.seaTake:
        if (TakeCardType.sea.index == roomEvent.pos) {
          _take(roomEvent.owner, roomEvent.card!, roomEvent.pos!);
        }
        break;
      case RoomEventAction.send:
        return _send(roomEvent.owner, roomEvent.card!);
      case RoomEventAction.touch:
        _touch(
            roomEvent.owner, roomEvent.pos!, roomEvent.src!, roomEvent.card!);
        break;
      case RoomEventAction.bar:
        _bar(roomEvent.owner, roomEvent.pos!, roomEvent.card!, roomEvent.src!);
        break;
      case RoomEventAction.takeBar:
        _takeBar(roomEvent.owner, roomEvent.pos!, roomEvent.card!);
        break;
      case RoomEventAction.darkBar:
        _darkBar(roomEvent.owner, roomEvent.pos!);
        break;
      case RoomEventAction.drawing:
        _drawing(roomEvent.owner, roomEvent.pos!, roomEvent.card!);
        break;
      case RoomEventAction.check:
        _check(roomEvent.owner, roomEvent.card!);
        break;
      case RoomEventAction.checkComplete:
        _checkComplete(roomEvent.owner, roomEvent.card!);
        break;
      case RoomEventAction.complete:
        _complete(roomEvent.owner, roomEvent.pos!);
        break;
      case RoomEventAction.pass:
        _pass(roomEvent.owner);
        break;
      case RoomEventAction.rob:
        _rob(roomEvent.owner, roomEvent.pos!, roomEvent.card!, roomEvent.src!);
        break;
      default:
        break;
    }
  }
}
