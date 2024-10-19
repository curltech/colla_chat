import 'dart:async';

import 'package:colla_chat/pages/majiang/card_util.dart';
import 'package:colla_chat/pages/majiang/room.dart';
import 'package:colla_chat/pages/majiang/split_card.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ParticipantState { pass, touch, bar, darkBar, drawing, complete }

/// 自摸牌，杠上牌
enum TakeCardType { self, bar, sea }

class ParticipantCard {
  final String peerId;

  final String name;

  Widget? avatarWidget;

  ///是否是机器人
  final bool robot;

  final int position;

  final String roomName;

  //积分
  final RxInt score = 0.obs;

  //手牌
  final RxList<String> handCards = <String>[].obs;

  //碰，杠牌，吃牌
  final RxList<SequenceCard> touchCards = <SequenceCard>[].obs;

  final RxList<SequenceCard> drawingCards = <SequenceCard>[].obs;

  //打出的牌
  final RxList<String> poolCards = <String>[].obs;

  final Rx<String?> takeCard = Rx<String?>(null);

  TakeCardType? takeCardType;

  /// 记录重要的事件
  final List<RoomEvent> roomEvents = [];

  final RxMap<ParticipantState, List<int>> participantState =
      RxMap<ParticipantState, List<int>>({});

  StreamController<RoomEvent> roomEventStreamController =
      StreamController<RoomEvent>.broadcast();

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  /// 杠牌次数
  int barCount = 0;

  /// 别人给自己杠牌的人
  List<int> barSenders = [];

  /// 包了自己的胡牌的人
  int? packer;

  ParticipantCard(
    this.peerId,
    this.name,
    this.position,
    this.roomName, {
    this.robot = false,
  }) {
    roomEventStreamSubscription =
        roomEventStreamController.stream.listen((RoomEvent roomEvent) {
      onRoomEvent(roomEvent);
    });
  }

  ParticipantCard.fromJson(Map json)
      : peerId = json['peerId'] == '' ? null : json['id'],
        name = json['name'],
        position = json['position'],
        roomName = json['roomName'],
        robot = json['robot'] == true || json['robot'] == 1 ? true : false;

  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'name': name,
      'position': position,
      'roomName': roomName,
      'robot': robot,
    };
  }

  clear() {
    participantState.clear();
    handCards.clear();
    touchCards.clear();
    drawingCards.clear();
    poolCards.clear();
    takeCard.value = null;
    takeCardType = null;
    barCount = 0;
    barSenders.clear();
    packer = null;
  }

  _updateParticipantState(ParticipantState state, int value) {
    List<int>? values = participantState[state];
    if (values == null) {
      values = [];
      participantState[state] = values;
    }
    values.add(value);
  }

  /// 排序
  handSort() {
    CardUtil.sort(handCards);
  }

  /// 检查碰牌
  int? _checkTouch(String card) {
    int length = handCards.length;
    if (length < 2) {
      return null;
    }
    for (int i = 1; i < handCards.length; ++i) {
      if (card == handCards[i] && card == handCards[i - 1]) {
        _updateParticipantState(ParticipantState.touch, i - 1);

        return i - 1;
      }
    }

    return null;
  }

  /// 检查打牌明杠
  int? _checkBar(String card) {
    int length = handCards.length;
    if (length < 4) {
      return null;
    }
    for (int i = 2; i < handCards.length; ++i) {
      if (card == handCards[i] &&
          card == handCards[i - 1] &&
          card == handCards[i - 2]) {
        _updateParticipantState(ParticipantState.bar, i - 2);
        _updateParticipantState(ParticipantState.touch, i - 2);
        return i - 2;
      }
    }

    return null;
  }

  /// 检查摸牌明杠，需要检查card与碰牌是否相同
  /// 返回的结果包含-1，则comingCard可杠，如果包含的数字不是-1，则表示手牌的可杠牌位置
  /// 返回为空，则不可杠
  List<int>? _checkTakeBar(String card) {
    if (touchCards.isEmpty) {
      return null;
    }
    List<int>? results;
    for (int i = 0; i < touchCards.length; ++i) {
      if (card == touchCards[i].cards[0]) {
        _updateParticipantState(ParticipantState.bar, -1);

        return [-1];
      }
    }
    for (int i = 0; i < handCards.length; ++i) {
      var handCard = handCards[i];
      for (int j = 0; j < touchCards.length; ++j) {
        if (handCard == touchCards[j].cards[0]) {
          _updateParticipantState(ParticipantState.bar, i);
          results ??= [];
          results.add(i);
        }
      }
    }

    return results;
  }

  /// 检查暗杠，就是检查加上摸牌card后，手上是否有连续的四张，如果有的话返回第一张的位置
  List<int>? _checkDarkBar(String card) {
    List<String> cards = [...handCards];
    cards.add(card);
    CardUtil.sort(cards);
    int length = cards.length;
    if (length < 4) {
      return null;
    }
    List<int>? pos;
    for (int i = 3; i < length; ++i) {
      if (cards[i] == cards[i - 1] &&
          cards[i] == cards[i - 2] &&
          cards[i] == cards[i - 3]) {
        pos ??= [];
        pos.add(i - 3);
        _updateParticipantState(ParticipantState.darkBar, i - 3);
      }
    }

    return pos;
  }

  /// 检查吃牌，card是上家打出的牌
  List<int>? _checkDrawing(String card) {
    if (!(card.startsWith('suo') ||
        card.startsWith('tong') ||
        card.startsWith('wan'))) {
      return null;
    }
    int sequence = CardUtil.sequence(card);
    if (sequence == -1) {
      return null;
    }
    bool success = false;
    CardType cardType = CardUtil.cardType(card);
    List<int>? pos;
    for (int i = 0; i < handCards.length; ++i) {
      String c = handCards[i];
      if (CardUtil.cardType(c) != cardType) {
        continue;
      }

      success = CardUtil.next(card, c);
      if (success && i + 1 < handCards.length) {
        String c1 = handCards[i + 1];
        success = CardUtil.next(c, c1);
        if (success) {
          pos ??= [];
          pos.add(i);
          _updateParticipantState(ParticipantState.drawing, i);
        }
      }
      success = CardUtil.next(c, card);
      if (success && i + 1 < handCards.length) {
        String c1 = handCards[i + 1];
        success = CardUtil.next(card, c1);
        if (success) {
          pos ??= [];
          pos.add(i);
          _updateParticipantState(ParticipantState.drawing, i);
        }
      }

      String c1 = handCards[i - 1];
      success = CardUtil.next(c1, c);
      if (success) {
        success = CardUtil.next(c, card);
        if (success) {
          pos ??= [];
          pos.add(i - 1);
          _updateParticipantState(ParticipantState.drawing, i - 1);
        }
      }
    }

    return pos;
  }

  /// 检查胡牌，card是自摸或者别人打出的牌，返回是否可能胡的牌
  CompleteType? _checkComplete(int owner, String card) {
    CompleteType? completeType;
    List<String> cards = [...handCards];
    cards.add(card);
    CardUtil.sort(cards);
    SplitCard splitCard = SplitCard();
    bool success = splitCard.check13_1(cards);
    if (success) {
      completeType = CompleteType.thirteenOne;
    }
    if (completeType == null) {
      int count = splitCard.splitLux7Pair(cards);
      if (count == 0) {
        completeType = CompleteType.pair7;
      }
      if (count > 0) {
        completeType = CompleteType.luxPair7;
      }
    }

    if (completeType == null) {
      success = splitCard.split(cards);
      if (success) {
        splitCard.sequenceCards.addAll(touchCards);
        splitCard.sequenceCards.addAll(drawingCards);
        completeType = splitCard.check();
      }
    }
    if (completeType != null) {
      if (completeType == CompleteType.small && takeCard.value == null) {
        completeType = null;
      } else {
        _updateParticipantState(ParticipantState.complete, completeType.index);
      }
    }

    return completeType;
  }

  /// 打牌，owner打出牌card，对其他人检查打的牌是否能够胡牌，杠牌和碰牌，返回检查的结果
  int? _send(int owner, String card) {
    if (owner == position) {
      if (card != takeCard.value) {
        handCards.remove(card);
        if (takeCard.value != null) {
          handCards.add(takeCard.value!);
        }
        CardUtil.sort(handCards);
      }
      takeCard.value = null;
      takeCardType = null;
      poolCards.add(card);

      return null;
    } else {
      CompleteType? completeType = _checkComplete(owner, card);
      int? pos = _checkBar(card);
      pos ??= _checkTouch(card);
      if (completeType != null) {
        return completeType.index;
      }
      if (pos != null) {
        return pos;
      }
    }

    return null;
  }

  Map<ParticipantState, List<int>> _check(int owner, String card) {
    _checkComplete(owner, card);
    _checkBar(card);
    _checkTouch(card);

    return participantState;
  }

  /// 碰牌,owner碰pos位置，sender打出的card牌
  bool _touch(int owner, int pos, int sender, String card) {
    if (position == owner) {
      if (handCards[pos] != card) {
        return false;
      }
      card = handCards.removeAt(pos);
      handCards.removeAt(pos);
      SequenceCard sequenceCard = SequenceCard(
          CardUtil.cardType(card), SequenceCardType.touch, [card, card, card]);
      touchCards.add(sequenceCard);
    } else {
      if (poolCards.last == card) {
        poolCards.removeLast();
      } else {
        return false;
      }
    }

    return true;
  }

  /// owner明杠位置pos的牌，分两种情况，摸牌杠牌和打牌杠牌
  /// 打牌杠牌的时候sender不为空，表示打牌的参与者
  /// pos表示杠牌的位置,如果摸牌杠牌的时候为手牌杠牌的位置，打牌杠牌的时候是杠牌的位置
  /// 返回值为杠的牌，为空表示未成功
  String? _bar(int owner, String card, {int? pos, int? sender}) {
    if (position == owner) {
      /// 摸牌杠牌，或者摸牌与已经碰的牌相同，或者手牌与已经碰的牌相同
      if (sender == null) {
        /// card必须与摸牌相同
        if (card != takeCard.value) {
          return null;
        }

        /// pos为null，摸牌杠，放入手牌，排序；不为空，手牌杠
        if (pos != null) {
          card = handCards.removeAt(pos);
        }
        CardUtil.sort(handCards);
        for (int i = 0; i < touchCards.length; ++i) {
          SequenceCard sequenceCard = touchCards[i];
          if (sequenceCard.cards[0] == card) {
            if (sequenceCard.cards.length < 4) {
              sequenceCard.cards.add(card);
            } else {
              sequenceCard.cards.removeRange(4, sequenceCard.cards.length);
            }
            takeCard.value = null;
            takeCardType = null;
            barCount++;
            for (int i = 0; i < 4; ++i) {
              if (i != pos) {
                barSenders.add(i);
              }
            }

            return card;
          }
        }
      } else {
        ///打牌杠牌，检查当前手牌的位置pos的牌是否相同
        if (pos == null || handCards[pos] != card) {
          return null;
        }
        card = handCards.removeAt(pos);
        handCards.removeAt(pos);
        handCards.removeAt(pos);
        SequenceCard sequenceCard = SequenceCard(CardUtil.cardType(card),
            SequenceCardType.bar, [card, card, card, card]);
        touchCards.add(sequenceCard);
        barCount++;
        barSenders.add(sender);
        barSenders.add(sender);
        barSenders.add(sender);

        return card;
      }
    }

    return null;
  }

  /// 暗杠牌，owner杠手上pos位置已有的四张牌（card==null）或者新进的card（card!=null）
  String? _darkBar(int owner, int pos, {String? card}) {
    if (position == owner) {
      if (card != null && handCards[pos] != card) {
        return null;
      }
      card = handCards.removeAt(pos);
      handCards.removeAt(pos);
      handCards.removeAt(pos);
      if (takeCard.value == card) {
        takeCard.value = null;
      } else {
        handCards.removeAt(pos);
      }
      SequenceCard sequenceCard = SequenceCard(CardUtil.cardType(card),
          SequenceCardType.darkBar, [card, card, card, card]);
      touchCards.add(sequenceCard);
      barCount++;
      for (int i = 0; i < 4; ++i) {
        if (i != pos) {
          barSenders.add(i);
          barSenders.add(i);
        }
      }

      return card;
    }

    return null;
  }

  /// 吃牌，owner在pos位置吃上家的牌card
  String? _drawing(int owner, int pos, String card) {
    if (position == owner) {
      handCards.removeAt(pos);
      handCards.removeAt(pos);
      SequenceCard sequenceCard = SequenceCard(CardUtil.cardType(card),
          SequenceCardType.sequence, [card, card, card]);
      touchCards.add(sequenceCard);
    }
    return card;
  }

  /// 胡牌，owner胡participantState中的可胡的牌形,pos表示可胡牌形数组的位置
  CompleteType? _complete(int owner, int pos) {
    if (position == owner) {
      List<int>? completes = participantState[ParticipantState.complete];
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
    if (position == owner) {
      participantState.clear();
    }
  }

  /// 摸牌，有三种摸牌，普通的自摸，海底捞的自摸，杠上自摸
  /// owner摸到card牌，takeCardType表示摸牌的方式
  List<int>? _take(int owner, String card, int pos) {
    TakeCardType? takeCardType = NumberUtil.toEnum(TakeCardType.values, pos);
    if (takeCardType == null) {
      return null;
    }
    if (position == owner) {
      takeCard.value = card;
      this.takeCardType = takeCardType;

      /// 检查摸到的牌，看需要采取的动作
      CompleteType? completeType = _checkComplete(owner, card);
      List<int>? pos = _checkDarkBar(card);
      pos ??= _checkTakeBar(card);
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
  CompleteType? _rob(int owner, int src, String card, int pos) {
    if (position == owner) {
      List<int>? completes = participantState[ParticipantState.complete];
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
        _bar(roomEvent.owner, roomEvent.card!,
            pos: roomEvent.pos!, sender: roomEvent.src);
        break;
      case RoomEventAction.darkBar:
        _darkBar(roomEvent.owner, roomEvent.pos!, card: roomEvent.card!);
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
        _rob(roomEvent.owner, roomEvent.src!, roomEvent.card!, roomEvent.pos!);
        break;
      default:
        break;
    }
  }
}
