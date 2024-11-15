import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum ActionType {
  bar,
  darkBar,
  complete,
  drawing,
  pass,
  selfComplete,
  touch,
}

class Action {
  static const String majiangPath = 'majiang/';

  final ActionType actionType;

  late final Sprite sprite;

  Action(this.actionType) {
    loadSprite();
  }

  loadSprite() async {
    Image image =
        await Flame.images.load('$majiangPath${actionType.name}.webp');
    sprite = Sprite(image);
  }
}

class Actions {
  final Map<ActionType, Action> actions = {};

  Actions() {
    init();
  }

  init() {
    for (var actionType in ActionType.values) {
      actions[actionType] = Action(actionType);
    }
  }
}
