/// 麻将牌的花色
enum Suit { wind, suo, tong, wan, none }

/// 风牌
enum WindSuit {
  east,
  south,
  west,
  north,
  center,
  fortune,
  whiteboard,
}

/// 对子,刻子,顺子,杠子
enum CardType {
  single,
  pair, //11
  straight, //123
  touch, //111
  bar, //1111
  darkBar, //1111
  straightPair, //122
  pairStraight, //112
  skipSequence, //134
  skipPair, //133
  pairSkip, //113
  skip, //135
}

// 胡牌类型
enum CompleteType {
  thirteenOne, //13幺
  oneNine, //19碰碰胡
  pureTouch, //清碰
  luxPair7, //豪华7对
  pureOneType, //清一色
  mixTouch, //混碰
  pair7, //7对
  mixOneType, //混一色
  touch, //碰碰胡
  small, //小胡
}

enum EnhanceType { lastOne, bar }

/// 麻将牌的次序
final List<int> rank = [1, 2, 3, 4, 5, 6, 7, 8, 9];
