import 'package:colla_chat/pages/game/poker/klondike/card.dart';

enum MoveMethod { drag, tap }

/// 一摞牌，可以认为是一个序列的牌
/// 定义了其中的牌的行为，能否移动，能否接收牌，能否移掉牌，能否获取牌，能否返回牌
abstract class Pile {
  /// Returns true if the [card] can be taken away from this pile and moved
  /// somewhere else. A tapping move may need additional validation.
  bool canMoveCard(Card card, MoveMethod method);

  /// Returns true if the [card] can be placed on top of this pile. The [card]
  /// may have other cards "attached" to it.
  bool canAcceptCard(Card card);

  /// Removes [card] from this pile; this method will only be called for a card
  /// that both belong to this pile, and for which [canMoveCard] returns true.
  void removeCard(Card card, MoveMethod method);

  /// Places a single [card] on top of this pile. This method will only be
  /// called for a card for which [canAcceptCard] returns true.
  void acquireCard(Card card);

  /// Returns a [card], which already belongs to this pile, to its proper place.
  void returnCard(Card card);
}
