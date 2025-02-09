import 'dart:ui';

import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum MahjongActionResult {
  // 成功
  success,
  // 参与者不匹配
  error,
  // 牌不存在
  exist,
  // 牌的数目不对
  count,
  // 检查有待定的行为
  check
}

class RoomEventActions {
  static const String mahjongPath = 'mahjong/';
  final Map<RoomEventAction, Sprite> roomEventActions = {};

  RoomEventActions() {
    init();
  }

  Future<Sprite> loadSprite(RoomEventAction outstandingAction) async {
    Image image =
        await Flame.images.load('$mahjongPath${outstandingAction.name}.webp');

    return Sprite(image);
  }

  init() async {
    for (var outstandingAction in RoomEventAction.values) {
      roomEventActions[outstandingAction] = await loadSprite(outstandingAction);
    }
  }

  Sprite? operator [](RoomEventAction outstandingAction) {
    return roomEventActions[outstandingAction];
  }
}

final RoomEventActions allOutstandingActions = RoomEventActions();
