import 'package:colla_chat/pages/game/mahjong/base/hand_pile.dart';
import 'package:colla_chat/pages/game/mahjong/base/participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/room_event.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/waste_pile.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:flame/game.dart';
import 'package:get/get.dart';

class RoomController {
  late double width;
  late double height;
  late Vector2 scale;

  final Rx<Room?> room = Rx<Room?>(null);

  RoomController() {
    init();
  }

  void init() {
    width = appDataProvider.secondaryBodyWidth + appDataProvider.bodyWidth;
    height = appDataProvider.totalSize.height - appDataProvider.toolbarHeight;
    if (width < height) {
      double temp = width;
      width = height;
      height = temp;
    }
    scale = Vector2(width * 0.8 / 1110, height * 0.8 / 650);
  }

  double x(double x) {
    return -width * 0.5 + x;
  }

  double y(double y) {
    return -height * 0.5 + y;
  }

  /// self是哪个方位的参与者，用于取参与者牌的数据
  /// 因为系统支持以哪个方位的参与者游戏
  /// 所以在玩的过程中可以切换方位，即可以模拟或者代替其他的参与者玩
  /// 比如，当前登录用户是东，除了可以打东的牌以外，通过切换方位也可以打南的牌
  /// 这个值可以直接用来取self区域的数据
  final Rx<ParticipantDirection> selfParticipantDirection =
      Rx<ParticipantDirection>(ParticipantDirection.east);

  /// 自己对应的参与者
  Participant? get selfParticipant {
    return room.value?.participants[selfParticipantDirection.value.index];
  }

  /// 参与者方位对应的轮参与者
  RoundParticipant? getRoundParticipant(
      ParticipantDirection participantDirection) {
    return room.value?.currentRound?.getRoundParticipant(participantDirection);
  }

  /// 根据selfParticipantDirection和输入的区域方位的值，计算输入的区域方位的数据方位
  ParticipantDirection getParticipantDirection(AreaDirection areaDirection) {
    int index = areaDirection.index + selfParticipantDirection.value.index;
    if (index > 3) {
      index = index - 4;
    }

    return NumberUtil.toEnum(ParticipantDirection.values, index)!;
  }

  /// 区域方位对应的轮参与者
  RoundParticipant? findRoundParticipant(AreaDirection areaDirection) {
    return room.value?.currentRound
        ?.getRoundParticipant(getParticipantDirection(areaDirection));
  }

  /// 当前轮
  Round? get currentRound {
    return room.value?.currentRound;
  }

  /// 区域方位对应的轮参与者的手牌数据
  HandPile? getHandPile(AreaDirection areaDirection) {
    return findRoundParticipant(areaDirection)?.handPile;
  }

  bool? isWin(AreaDirection areaDirection) {
    return findRoundParticipant(areaDirection)?.isWin.value;
  }

  /// 区域方位对应的轮参与者的河牌数据
  WastePile? getWastePile(AreaDirection areaDirection) {
    return findRoundParticipant(areaDirection)?.wastePile;
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
      return 2;
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
}

final RoomController roomController = RoomController();
