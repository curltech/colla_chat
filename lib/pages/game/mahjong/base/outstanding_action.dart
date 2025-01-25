import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum MahjongAction { pass, touch, bar, darkBar, chow, win, selfWin }

class MahjongActions {
  static const String mahjongPath = 'mahjong/';
  final Map<MahjongAction, Sprite> outstandingActions = {};

  MahjongActions() {
    init();
  }

  Future<Sprite> loadSprite(MahjongAction outstandingAction) async {
    Image image =
        await Flame.images.load('$mahjongPath${outstandingAction.name}.webp');

    return Sprite(image);
  }

  init() async {
    for (var outstandingAction in MahjongAction.values) {
      outstandingActions[outstandingAction] =
          await loadSprite(outstandingAction);
    }
  }

  Sprite? operator [](MahjongAction outstandingAction) {
    return outstandingActions[outstandingAction];
  }
}

final MahjongActions allOutstandingActions = MahjongActions();
