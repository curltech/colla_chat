import 'dart:async';

import 'package:colla_chat/pages/game/majiang/base/card.dart' as majiangCard;
import 'package:colla_chat/pages/game/majiang/base/card_background_sprite.dart';
import 'package:colla_chat/pages/game/majiang/base/room.dart';
import 'package:colla_chat/pages/game/majiang/base/round.dart';
import 'package:colla_chat/pages/game/majiang/base/stock_pile.dart';
import 'package:colla_chat/pages/game/majiang/component/card_component.dart';
import 'package:colla_chat/pages/game/majiang/component/majiang_flame_game.dart';
import 'package:colla_chat/pages/game/majiang/room_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// 摸牌的麻将牌
class StockPileComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameRef<MajiangFlameGame> {
  StockPileComponent({super.scale}) {
    position = Vector2(5, 18);
  }

  StockPile? get stockPile {
    return roomController.room.value?.currentRound?.stockPile;
  }

  /// 绘制牌的图像，有相对的偏移量，旋转，放大等参数
  void loadStockPile() {
    StockPile? stockPile = this.stockPile;
    if (stockPile == null) {
      return;
    }
    Round? round = roomController.currentRound;
    if (round == null) {
      return;
    }
    int length = 26;
    int barCount = round.barCount;
    if (barCount.isOdd) {
      length = 25;
    }
    CardBackgroundType cardBackgroundType = CardBackgroundType.opponentbar;
    double x = 0;
    double y = 0;
    int priority = 12;
    List<majiangCard.Card> cards;
    if (stockPile.cards.length > length) {
      cards = stockPile.cards.sublist(stockPile.cards.length - length);
    } else {
      cards = stockPile.cards;
    }
    List<majiangCard.Card> upCards = [];
    List<majiangCard.Card> downCards = [];
    for (int i = 0; i < cards.length; ++i) {
      if ((barCount.isOdd && cards.length.isOdd) ||
          (!barCount.isOdd && !cards.length.isOdd)) {
        if (i.isOdd) {
          downCards.add(cards[i]);
        } else {
          upCards.add(cards[i]);
        }
      } else {
        if (i.isOdd) {
          upCards.add(cards[i]);
        } else {
          downCards.add(cards[i]);
        }
      }
    }
    for (int i = 0; i < downCards.length; ++i) {
      majiangCard.Card card = stockPile.cards[i];
      x = 0;
      Vector2 position = Vector2(x, y);
      x += 35;
      CardComponent cardComponent = CardComponent(
          card, AreaDirection.self, cardBackgroundType,
          position: position, priority: priority);
      add(cardComponent);
    }
    for (int i = 0; i < upCards.length; ++i) {
      majiangCard.Card card = stockPile.cards[i];
      if ((barCount.isOdd && cards.length.isOdd) ||
          (!barCount.isOdd && !cards.length.isOdd)) {
      } else {
        x += 35;
      }
      y = -10;
      Vector2 position = Vector2(x, y);
      x += 35;
      CardComponent cardComponent = CardComponent(
          card, AreaDirection.self, cardBackgroundType,
          position: position, priority: priority);
      add(cardComponent);
    }
  }

  @override
  FutureOr<void> onLoad() {
    loadStockPile();

    return super.onLoad();
  }
}
