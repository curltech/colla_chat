import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/component/hand_pile_component.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 手牌区域
class HandAreaComponent extends RectangleComponent
    with HasGameRef<MahjongFlameGame> {
  /// 区域的方位，用于显示的方式
  final AreaDirection areaDirection;

  HandPileComponent? handPileComponent;

  HandAreaComponent(this.areaDirection) {
    _init();
  }

  _init() {
    if (areaDirection == AreaDirection.self) {
      position = Vector2(
          MahjongFlameGame.x(
              MahjongFlameGame.width * MahjongFlameGame.selfWidthRadio),
          MahjongFlameGame.y(MahjongFlameGame.height *
              (1 - MahjongFlameGame.selfHeightRadio)));
      size = Vector2(
          MahjongFlameGame.width * MahjongFlameGame.selfHandWidthRadio,
          MahjongFlameGame.height * MahjongFlameGame.selfHeightRadio);
      paint = Paint()
        ..color = Colors.teal
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.next) {
      position = Vector2(
          MahjongFlameGame.x(MahjongFlameGame.width *
              (1 -
                  MahjongFlameGame.nextWidthRadio -
                  MahjongFlameGame.nextHandWidthRadio)),
          MahjongFlameGame.y(
              MahjongFlameGame.height * MahjongFlameGame.opponentHeightRadio));
      size = Vector2(
          MahjongFlameGame.width * MahjongFlameGame.nextHandWidthRadio,
          MahjongFlameGame.height * MahjongFlameGame.nextHeightRadio);
      paint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.opponent) {
      position = Vector2(
          MahjongFlameGame.x(
              MahjongFlameGame.width * MahjongFlameGame.opponentWidthRadio),
          MahjongFlameGame.y(0));
      size = Vector2(
          MahjongFlameGame.width * MahjongFlameGame.opponentHandWidthRadio,
          MahjongFlameGame.height * MahjongFlameGame.opponentHeightRadio);
      paint = Paint()
        ..color = Colors.blueGrey
        ..style = PaintingStyle.fill;
    }
    if (areaDirection == AreaDirection.previous) {
      position = Vector2(
          MahjongFlameGame.x(
              MahjongFlameGame.width * MahjongFlameGame.previousWidthRadio),
          MahjongFlameGame.y(
              MahjongFlameGame.height * MahjongFlameGame.opponentHeightRadio));
      size = Vector2(
          MahjongFlameGame.width * MahjongFlameGame.previousHandWidthRadio,
          MahjongFlameGame.height * MahjongFlameGame.previousHeightRadio);
      paint = Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.fill;
    }
  }

  loadHandPile() {
    if (handPileComponent != null) {
      remove(handPileComponent!);
    }
    Room? room = roomController.room.value;
    if (room != null) {
      Vector2 position= Vector2(0, 20);
      if (areaDirection == AreaDirection.opponent) {
        position= Vector2(0, 50);
      }
      if (areaDirection == AreaDirection.next) {
        position= Vector2(10, 0);
      }
      if (areaDirection == AreaDirection.previous) {
        position= Vector2(60, 0);
      }
      handPileComponent = HandPileComponent(areaDirection,
          position: position, scale: Vector2(0.85, 0.85));
      add(handPileComponent!);
    }
  }
}
