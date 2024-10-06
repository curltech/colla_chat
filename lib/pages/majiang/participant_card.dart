import 'dart:async';

import 'package:colla_chat/pages/majiang/card_util.dart';
import 'package:colla_chat/pages/majiang/room.dart';
import 'package:colla_chat/pages/majiang/split_card.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ParticipantState { pass, touch, bar, darkbar, drawing, complete }

/// 自摸牌，杠上牌
enum ComingCardType { self, bar, sea }

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

  ComingCardType? comingCardType;

  final RxMap<ParticipantState, List<int>> participantState =
      RxMap<ParticipantState, List<int>>({});

  late final StreamSubscription<RoomEvent> roomEventStreamSubscription;

  /// 杠牌次数
  int barCount = 0;

  /// 别人给自己杠牌的人
  List<int> barSenders = [];

  /// 包了自己的胡牌的人
  int? packer;

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
    participantState.clear();
    handCards.clear();
    touchCards.clear();
    drawingCards.clear();
    poolCards.clear();
    comingCard.value = null;
    comingCardType = null;
    barCount = 0;
    barSenders.clear();
    packer = null;
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

  /// 检查打牌明杠
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

  /// 检查摸牌明杠，需要检查card与碰牌是否相同
  /// 返回的结果包含-1，则comingCard可杠，如果包含的数字不是-1，则表示手牌的可杠牌位置
  /// 返回为空，则不可杠
  List<int>? checkTakeBar(String card) {
    if (touchCards.isEmpty) {
      return null;
    }
    List<int>? results;
    for (int i = 0; i < touchCards.length; ++i) {
      if (card == touchCards[i].cards[0]) {
        updateParticipantState(ParticipantState.bar, -1);

        return [-1];
      }
    }
    for (int i = 0; i < handCards.length; ++i) {
      var handCard = handCards[i];
      for (int j = 0; j < touchCards.length; ++j) {
        if (handCard == touchCards[j].cards[0]) {
          updateParticipantState(ParticipantState.bar, i);
          results ??= [];
          results.add(i);
        }
      }
    }

    return results;
  }

  /// 检查暗杠，就是检查加上摸牌后，手上是否有连续的四张，如果有的话返回第一张的位置
  List<int>? checkDarkBar({String? card}) {
    List<String> cards = [...handCards];
    if (card != null) {
      cards.add(card);
      CardUtil.sort(cards);
    }
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
        updateParticipantState(ParticipantState.darkbar, i - 3);
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
        String c1 = handCards[i + 1];
        success = CardUtil.next(c, c1);
        if (success) {
          pos ??= [];
          pos.add(i);
          updateParticipantState(ParticipantState.drawing, i);
        }
      }
      success = CardUtil.next(c, card);
      if (success && i + 1 < handCards.length) {
        String c1 = handCards[i + 1];
        success = CardUtil.next(card, c1);
        if (success) {
          pos ??= [];
          pos.add(i);
          updateParticipantState(ParticipantState.drawing, i);
        }
      }

      String c1 = handCards[i - 1];
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
      if (completeType == CompleteType.small && comingCard.value == null) {
        completeType = null;
      } else {
        updateParticipantState(ParticipantState.complete, completeType.index);
      }
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
    comingCardType = null;
    poolCards.add(card);
  }

  /// 碰牌
  bool touch(int pos, {String? card}) {
    if (card != null && handCards[pos] != card) {
      return false;
    }
    card = handCards.removeAt(pos);
    handCards.removeAt(pos);
    SequenceCard sequenceCard = SequenceCard(
        CardUtil.cardType(card), SequenceCardType.touch, [card, card, card]);
    touchCards.add(sequenceCard);

    return true;
  }

  /// 明杠牌，分三种情况
  /// pos为-1，表示是摸牌可杠，否则表示手牌可杠的位置
  /// 返回值为杠的牌，为空表示未成功
  String? bar(int pos, {int? sender, String? card}) {
    /// 摸牌杠牌
    if (card == null && comingCard.value != null) {
      if (pos == -1) {
        card = comingCard.value;
      } else {
        card = handCards.removeAt(pos);
      }
      for (int i = 0; i < touchCards.length; ++i) {
        SequenceCard sequenceCard = touchCards[i];
        if (sequenceCard.cards[0] == card) {
          if (sequenceCard.cards.length < 4) {
            sequenceCard.cards.add(card!);
          } else {
            sequenceCard.cards.removeRange(4, sequenceCard.cards.length);
          }
          CardUtil.sort(handCards);
          comingCard.value = null;
          comingCardType = null;
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
      ///打牌杠牌
      if (card != null && handCards[pos] != card) {
        return null;
      }
      card = handCards.removeAt(pos);
      handCards.removeAt(pos);
      handCards.removeAt(pos);
      SequenceCard sequenceCard = SequenceCard(CardUtil.cardType(card),
          SequenceCardType.bar, [card, card, card, card]);
      touchCards.add(sequenceCard);
      barCount++;
      if (sender != null) {
        barSenders.add(sender);
        barSenders.add(sender);
        barSenders.add(sender);
      }

      return card;
    }

    return null;
  }

  /// 暗杠牌
  String? darkBar(int pos, {String? card}) {
    if (card != null && handCards[pos] != card) {
      return null;
    }
    card = handCards.removeAt(pos);
    handCards.removeAt(pos);
    handCards.removeAt(pos);
    handCards.removeAt(pos);
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

  /// 吃牌
  bool drawing(int pos, String card) {
    handCards.removeAt(pos);
    handCards.removeAt(pos);
    SequenceCard sequenceCard = SequenceCard(
        CardUtil.cardType(card), SequenceCardType.sequence, [card, card, card]);
    touchCards.add(sequenceCard);

    return true;
  }

  /// 胡牌
  CompleteType? complete() {
    List<int>? completes = participantState[ParticipantState.complete];
    if (completes != null && completes.isNotEmpty) {
      int complete = completes.first;
      CompleteType? completeType =
          NumberUtil.toEnum(CompleteType.values, complete);
      if (completeType != null) {
        logger.i('complete:$completeType');
      }

      return completeType;
    }

    return null;
  }

  /// 过牌
  pass() {
    participantState.clear();
  }

  /// 摸牌
  take(String card, ComingCardType comingCardType) {
    comingCard.value = card;
    this.comingCardType = comingCardType;
    takeCheck(card);
  }

  /// 检查摸到的牌，看需要采取的动作
  takeCheck(String card) {
    CompleteType? completeType = checkComplete(card);
    List<int>? results = checkDarkBar(card: card);
    results = checkTakeBar(card);
  }

  onRoomEvent(RoomEvent roomEvent) {}
}
