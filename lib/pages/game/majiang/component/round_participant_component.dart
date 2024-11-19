import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/RoundParticipant.dart';
import 'package:colla_chat/pages/game/majiang/base/participant.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// flame引擎渲染的麻将牌
class RoundParticipantComponent extends PositionComponent
    with TapCallbacks, HasGameRef<MajiangFlameGame> {
  RoundParticipantComponent(this.roundParticipant, this.direction,
      {super.position, super.size});

  final RoundParticipant roundParticipant;

  /// 0:自己，1:下家，2:对家，3:上家
  final int direction;

  SpriteComponent? spriteComponent;
  TextComponent? textComponent;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadTRoundParticipant() {
    if (spriteComponent != null) {
      remove(spriteComponent!);
    }
    if (textComponent != null) {
      remove(textComponent!);
    }
    Participant participant = roundParticipant.participant;
    Sprite? sprite = participant.sprite;
    if (sprite != null) {
      spriteComponent = SpriteComponent(
          sprite: sprite, position: Vector2(0, 0), size: Vector2(32, 32));
      add(spriteComponent!);
    }
    String name = participant.name;
    TextPaint textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12.0,
      ),
    );
    textComponent = TextComponent(
        text: name, textRenderer: textPaint, position: Vector2(0, 32));
    add(textComponent!);
  }

  @override
  FutureOr<void> onLoad() {
    loadTRoundParticipant();

    return super.onLoad();
  }
}
