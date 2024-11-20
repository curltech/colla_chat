import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum OutstandingAction {
  pass,
  touch,
  bar,
  darkBar,
  drawing,
  complete,
  selfComplete
}

class OutstandingActions {
  static const String majiangPath = 'majiang/';
  final Map<OutstandingAction, Sprite> outstandingActions = {};

  OutstandingActions() {
    init();
  }

  Future<Sprite> loadSprite(OutstandingAction outstandingAction) async {
    Image image =
        await Flame.images.load('$majiangPath${outstandingAction.name}.webp');

    return Sprite(image);
  }

  init() async {
    for (var outstandingAction in OutstandingAction.values) {
      outstandingActions[outstandingAction] =
          await loadSprite(outstandingAction);
    }
  }

  Sprite? operator [](OutstandingAction outstandingAction) {
    return outstandingActions[outstandingAction];
  }
}

final OutstandingActions allOutstandingActions = OutstandingActions();
