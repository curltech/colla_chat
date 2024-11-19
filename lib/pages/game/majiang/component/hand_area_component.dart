import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/component/hand_pile_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';

/// 手牌区域
class HandAreaComponent extends PositionComponent
    with HasGameRef<MajiangFlameGame> {
  final int direction;

  HandPileComponent? handPileComponent;

  HandAreaComponent(this.direction) {
    _init();
  }

  _init() {
    if (direction == 0) {
      position = Vector2(
          MajiangFlameGame.x(
              MajiangFlameGame.width * MajiangFlameGame.selfWidthRadio),
          MajiangFlameGame.y(MajiangFlameGame.height *
              (1 - MajiangFlameGame.selfHeightRadio)));
      size = Vector2(
          MajiangFlameGame.width * MajiangFlameGame.selfHandWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.selfHeightRadio);
      // paint = Paint()
      //   ..color = Colors.teal
      //   ..style = PaintingStyle.fill;
    }
    if (direction == 1) {
      position = Vector2(
          MajiangFlameGame.x(MajiangFlameGame.width *
              (1 -
                  MajiangFlameGame.nextWidthRadio -
                  MajiangFlameGame.nextHandWidthRadio)),
          MajiangFlameGame.y(
              MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio));
      size = Vector2(
          MajiangFlameGame.width * MajiangFlameGame.nextHandWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.nextHeightRadio);
      // paint = Paint()
      //   ..color = Colors.yellow
      //   ..style = PaintingStyle.fill;
    }
    if (direction == 2) {
      position = Vector2(
          MajiangFlameGame.x(
              MajiangFlameGame.width * MajiangFlameGame.opponentWidthRadio),
          MajiangFlameGame.y(0));
      size = Vector2(
          MajiangFlameGame.width * MajiangFlameGame.opponentHandWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio);
      // paint = Paint()
      //   ..color = Colors.blueGrey
      //   ..style = PaintingStyle.fill;
    }
    if (direction == 3) {
      position = Vector2(
          MajiangFlameGame.x(
              MajiangFlameGame.width * MajiangFlameGame.previousWidthRadio),
          MajiangFlameGame.y(
              MajiangFlameGame.height * MajiangFlameGame.opponentHeightRadio));
      size = Vector2(
          MajiangFlameGame.width * MajiangFlameGame.previousHandWidthRadio,
          MajiangFlameGame.height * MajiangFlameGame.previousHeightRadio);
      // paint = Paint()
      //   ..color = Colors.purple
      //   ..style = PaintingStyle.fill;
    }
  }

  loadHandPile() {
    if (handPileComponent != null) {
      remove(handPileComponent!);
    }
    Room? room = roomController.room.value;
    if (room != null) {
      HandPile? handPile =
          room.currentRound?.roundParticipants[direction].handPile;
      if (handPile != null) {
        handPileComponent = HandPileComponent(handPile, direction,
            position: Vector2(10, 10), scale: Vector2(0.85, 0.85));
        add(handPileComponent!);
      }
    }
  }
}
