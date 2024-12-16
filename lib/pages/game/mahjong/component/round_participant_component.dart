import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/base/round.dart';
import 'package:colla_chat/pages/game/mahjong/base/round_participant.dart';
import 'package:colla_chat/pages/game/mahjong/base/participant.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// flame引擎渲染的麻将牌
class RoundParticipantComponent extends PositionComponent
    with TapCallbacks, HasGameRef<MahjongFlameGame> {
  RoundParticipantComponent(this.roundParticipant,
      {super.position, super.size});

  final RoundParticipant roundParticipant;

  SpriteComponent? spriteComponent;
  TextComponent? textComponent;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadRoundParticipant() {
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
    int banker = roundParticipant.round.banker;
    int creator = roundParticipant.round.room.creator;
    int index = roundParticipant.index;
    String name = participant.name;
    if (creator == index) {
      name = '$name\n${AppLocalizations.t('creator')}';
    }
    if (banker == index) {
      name = '$name\n${AppLocalizations.t('banker')}';
    }
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
    loadRoundParticipant();

    return super.onLoad();
  }
}
