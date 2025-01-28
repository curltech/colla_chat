import 'package:colla_chat/pages/game/mahjong/base/suit.dart';

class MahjongActionStrategy {
  /// 可能的胡牌目标
  Set<WinType> winGoals = {};

  /// 胡牌目标的花色
  Suit? suitGoal;

  MahjongActionStrategy();
}
