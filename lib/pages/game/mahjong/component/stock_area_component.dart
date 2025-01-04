import 'package:colla_chat/pages/game/mahjong/base/room.dart';
import 'package:colla_chat/pages/game/mahjong/component/mahjong_flame_game.dart';
import 'package:colla_chat/pages/game/mahjong/component/stock_pile_component.dart';
import 'package:colla_chat/pages/game/mahjong/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 摸牌区域
class StockAreaComponent extends RectangleComponent
    with HasGameRef<MahjongFlameGame> {
  StockPileComponent? stockPileComponent;

  StockAreaComponent() {
    _init();
  }

  _init() {
    position = Vector2(
        roomController.x(roomController.width *
            (MahjongFlameGame.previousWidthRadio +
                MahjongFlameGame.previousHandWidthRadio +
                MahjongFlameGame.previousWasteWidthRadio)),
        roomController.y(roomController.height *
            (MahjongFlameGame.opponentHeightRadio +
                MahjongFlameGame.opponentWasteHeightRadio)));
    size = Vector2(roomController.width * MahjongFlameGame.stockWidthRadio,
        roomController.height * MahjongFlameGame.stockHeightRadio);
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
      stockPileComponent = StockPileComponent(scale: roomController.scale);
      add(stockPileComponent!);
    }
  }
}
