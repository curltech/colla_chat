import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/RoundParticipant.dart';
import 'package:colla_chat/pages/game/majiang/base/card.dart';
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/base/format_card.dart';
import 'package:colla_chat/pages/game/majiang/base/participant.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/component/card_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// flame引擎渲染的麻将牌
class RoundParticipantComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameRef<MajiangFlameGame> {
  RoundParticipantComponent(this.roundParticipant, this.direction,
      {super.position});

  final RoundParticipant roundParticipant;

  /// 0:自己，1:下家，2:对家，3:上家
  final int direction;

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void _loadTRoundParticipant() {
    Participant participant = roundParticipant.participant;
    Sprite? sprite = participant.sprite;
    if (sprite != null) {
      add(SpriteComponent(sprite: sprite));
    }
    String name = participant.name;
    add(TextBoxComponent(text: name));
  }

  @override
  FutureOr<void> onLoad() {
    _loadTRoundParticipant();

    return super.onLoad();
  }
}
