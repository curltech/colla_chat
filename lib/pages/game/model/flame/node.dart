import 'dart:ui' as ui;

/// 一对一，包含的一对多，组合的一对多，多对多
enum RelationshipType {
  direct,
  contain,
  composite,
  many,
  inherit,
}

class NodeRelationship {
  final Node src;
  final Node dst;
  final RelationshipType relationshipType;
  int? srcCount;
  int? dstCount;

  NodeRelationship(this.src, this.dst, this.relationshipType);
}

abstract class Node {
  final String name;

  final bool isAbstract;

  ui.Image? image;

  // NodeComponentItem? item;

  /// this is the cached position if this position is passed then it will get
  /// cached and then position can be reused instead of regenerating the whole
  /// node position randomly
  ui.Offset? cachedPosition;

  Node(this.name, this.isAbstract);
}
