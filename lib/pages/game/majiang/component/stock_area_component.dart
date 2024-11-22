import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/component/stock_pile_component.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 摸牌区域
class StockAreaComponent extends RectangleComponent
    with HasGameRef<MajiangFlameGame> {
  StockPileComponent? stockPileComponent;

  StockAreaComponent() {
    _init();
  }

  _init() {
    position = Vector2(
        MajiangFlameGame.x(MajiangFlameGame.width *
            (MajiangFlameGame.previousWidthRadio +
                MajiangFlameGame.previousHandWidthRadio +
                MajiangFlameGame.previousWasteWidthRadio)),
        MajiangFlameGame.y(MajiangFlameGame.height *
            (MajiangFlameGame.opponentHeightRadio +
                MajiangFlameGame.opponentWasteHeightRadio)));
    size = Vector2(MajiangFlameGame.width * MajiangFlameGame.stockWidthRadio,
        MajiangFlameGame.height * MajiangFlameGame.stockHeightRadio);
    paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke;
  }

  loadStockPile() {
    if (stockPileComponent != null) {
      remove(stockPileComponent!);
      stockPileComponent = null;
    }
    Room? room = roomController.room.value;
    if (room != null) {
      stockPileComponent = StockPileComponent(scale: Vector2(0.9, 0.9));
      add(stockPileComponent!);
    }
  }
}
