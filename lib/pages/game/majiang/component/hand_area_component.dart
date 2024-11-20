import 'package:colla_chat/pages/game/majiang/base/hand_pile.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/component/hand_pile_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';

/// 手牌区域
class HandAreaComponent extends PositionComponent
    with HasGameRef<MajiangFlameGame> {
  /// 区域的方位，用于显示的方式
  final AreaDirection areaDirection;

  HandPileComponent? handPileComponent;

  HandAreaComponent(this.areaDirection) {
    _init();
  }

  _init() {
    if (areaDirection == AreaDirection.self) {
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
    if (areaDirection == AreaDirection.next) {
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
    if (areaDirection == AreaDirection.opponent) {
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
    if (areaDirection == AreaDirection.previous) {
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
      Vector2 position= Vector2(10, 10);
      if (areaDirection == AreaDirection.opponent) {
        position= Vector2(10, 50);
      }
      if (areaDirection == AreaDirection.next) {
        position= Vector2(10, 10);
      }
      if (areaDirection == AreaDirection.previous) {
        position= Vector2(60, 10);
      }
      handPileComponent = HandPileComponent(areaDirection,
          position: position, scale: Vector2(0.85, 0.85));
      add(handPileComponent!);
    }
  }
}
