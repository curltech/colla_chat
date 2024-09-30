import 'dart:async';

import 'package:colla_chat/pages/majiang/card_util.dart';
import 'package:colla_chat/pages/majiang/room.dart';
import 'package:colla_chat/pages/majiang/split_card.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ParticipantState { pass, touch, bar, darkbar, drawing, complete }

class ParticipantCard {
  final String peerId;

  final String name;

  Widget? avatarWidget;

  ///是否是机器人
  final bool robot;

  //积分
  final RxInt score = 0.obs;

  //手牌
  final RxList<String> handCards = <String>[].obs;

  //碰，杠牌，吃牌
  final RxList<SequenceCard> touchCards = <SequenceCard>[].obs;

  final RxList<SequenceCard> drawingCards = <SequenceCard>[].obs;

  //打出的牌
  final RxList<String> poolCards = <String>[].obs;

  final Rx<String?> comingCard = Rx<String?>(null);

  final RxMap<ParticipantState, List<int>> participantState =
      RxMap<ParticipantState, List<int>>({});

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  ParticipantCard(this.peerId, this.name,
      {this.robot = false,
      required StreamController<RoomEvent> roomEventStreamController}) {
    roomEventStreamSubscription =
        roomEventStreamController.stream.listen((RoomEvent roomEvent) {
      onRoomEvent(roomEvent);
    });
  }

  ParticipantCard.fromJson(Map json)
      : peerId = json['peerId'] == '' ? null : json['id'],
        name = json['name'],
        robot = json['robot'] == true || json['robot'] == 1 ? true : false;

  Map<String, dynamic> toJson() {
    return {
      'peerId': peerId,
      'name': name,
      'robot': robot,
    };
  }

  clear() {
    handCards.clear();
    touchCards.clear();
    drawingCards.clear();
    poolCards.clear();
  }

  updateParticipantState(ParticipantState state, int value) {
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

  List<String> get allTouchCards {
    List<String> cards = [];
    for (SequenceCard touchCard in touchCards.value) {
      cards.addAll(touchCard.cards);
    }

    return cards;
  }

  List<String> get allDrawingCards {
    List<String> cards = [];
    for (SequenceCard drawingCard in drawingCards.value) {
      cards.addAll(drawingCard.cards);
    }

    return cards;
  }

  /// 检查碰牌
  int checkTouch(String card) {
    int length = handCards.length;
    if (length < 2) {
      return -1;
    }
    for (int i = 1; i < handCards.length; ++i) {
      if (card == handCards[i] && card == handCards[i - 1]) {
        updateParticipantState(ParticipantState.touch, i - 1);

        return i - 1;
      }
    }

    return -1;
  }

  /// 检查明杠
  int checkBar(String card) {
    int length = handCards.length;
    if (length < 4) {
      return -1;
    }
    for (int i = 2; i < handCards.length; ++i) {
      if (card == handCards[i] &&
          card == handCards[i - 1] &&
          card == handCards[i - 2]) {
        updateParticipantState(ParticipantState.bar, i - 2);
        updateParticipantState(ParticipantState.touch, i - 2);
        return i - 2;
      }
    }

    return -1;
  }

  /// 检查暗杠
  List<int>? checkDarkBar({String? card}) {
    List<String> cards = [...handCards];
    if (card != null) {
      cards.add(card);
    }
    int length = handCards.length;
    if (length < 4) {
      return null;
    }
    List<int>? pos;
    for (int i = 3; i < handCards.length; ++i) {
      if (handCards[i] == handCards[i - 1] &&
          handCards[i] == handCards[i - 2] &&
          handCards[i] == handCards[i - 3]) {
        pos ??= [];
        pos.add(i - 3);
      }
    }

    return pos;
  }

  /// 检查吃牌
  List<int>? checkDrawing(String card) {
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
        String c1 = handCards[i + i];
        success = CardUtil.next(c, c1);
        if (success) {
          pos ??= [];
          pos.add(i);
          updateParticipantState(ParticipantState.drawing, i);
        }
      }
      success = CardUtil.next(c, card);
      if (success && i + 1 < handCards.length) {
        String c1 = handCards[i + i];
        success = CardUtil.next(card, c1);
        if (success) {
          pos ??= [];
          pos.add(i);
          updateParticipantState(ParticipantState.drawing, i);
        }
      }

      String c1 = handCards[i - i];
      success = CardUtil.next(c1, c);
      if (success) {
        success = CardUtil.next(c, card);
        if (success) {
          pos ??= [];
          pos.add(i - 1);
          updateParticipantState(ParticipantState.drawing, i - 1);
        }
      }
    }

    return pos;
  }

  /// 检查胡牌
  CompleteType? checkComplete(String card) {
    CompleteType? completeType;
    List<String> cards = [...handCards];
    cards.add(card);
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
      updateParticipantState(ParticipantState.complete, completeType.index);
    }

    return completeType;
  }

  /// 打牌
  send(String card) {
    if (card != comingCard.value) {
      handCards.remove(card);
      if (comingCard.value != null) {
        handCards.add(comingCard.value!);
      }
      CardUtil.sort(handCards);
    }
    comingCard.value = null;
    poolCards.add(card);
  }

  /// 碰牌
  bool touch(int pos, {String? card}) {
    if (card != null && handCards[pos] != card) {
      return false;
    }
    card = handCards.removeAt(pos);
    handCards.removeAt(pos + 1);
    SequenceCard sequenceCard = SequenceCard(
        CardUtil.cardType(card), SequenceCardType.touch, [card, card, card]);
    touchCards.add(sequenceCard);

    return true;
  }

  /// 明杠牌
  bool bar(int pos, {String? card}) {
    if (card != null && handCards[pos] != card) {
      return false;
    }
    card = handCards.removeAt(pos);
    handCards.removeAt(pos + 1);
    handCards.removeAt(pos + 2);
    SequenceCard sequenceCard = SequenceCard(CardUtil.cardType(card),
        SequenceCardType.bar, [card, card, card, card]);
    touchCards.add(sequenceCard);

    return true;
  }

  /// 暗杠牌
  darkBar(int pos, {String? card}) {
    if (card != null && handCards[pos] != card) {
      return false;
    }
    card = handCards.removeAt(pos);
    handCards.removeAt(pos + 1);
    handCards.removeAt(pos + 2);
    handCards.removeAt(pos + 3);
    SequenceCard sequenceCard = SequenceCard(CardUtil.cardType(card),
        SequenceCardType.darkBar, [card, card, card, card]);
    touchCards.add(sequenceCard);
  }

  /// 吃牌
  drawing(int pos, String card) {
    handCards.removeAt(pos);
    handCards.removeAt(pos);
    SequenceCard sequenceCard = SequenceCard(
        CardUtil.cardType(card), SequenceCardType.sequence, [card, card, card]);
    touchCards.add(sequenceCard);
  }

  /// 胡牌
  CompleteType? complete() {
    List<int>? completes = participantState[ParticipantState.complete];
    if (completes != null && completes.isNotEmpty) {
      int complete = completes.first;
      CompleteType? completeType =
          NumberUtil.toEnum(CompleteType.values, complete);
      if (completeType != null) {
        logger.i('complete!');
      }

      return completeType;
    }

    return null;
  }

  /// 过牌
  pass() {
    participantState.clear();
  }

  /// 摸牌，peerId为空，自己摸牌，不为空，别人摸牌
  take(String card) {
    comingCard.value = card;
    takeCheck(card);
  }

  takeCheck(String card) {
    CompleteType? completeType = checkComplete(card);
    List<int>? results = checkDarkBar(card: card);
  }

  onRoomEvent(RoomEvent roomEvent) {}
}
