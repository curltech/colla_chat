import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// [LineComponent] 在src节点和dst关系节点之间画关系的连线
class LineComponent extends PositionComponent with HasGameRef<ModelFlameGame> {
  LineComponent({required this.nodeRelationship}) : super();

  /// [Node] draws line to its relationship nodes，this node is src node
  final NodeRelationship nodeRelationship;

  Paint defaultPaint(lineFrom, lineTo) {
    return Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5;
  }

  @override
  Future<void> onLoad() async {}

  @override
  void render(Canvas canvas) {
    Paint paint = BasicPalette.red.paint();
    paint = defaultPaint(nodeRelationship.src!, nodeRelationship.dst!);
    canvas.drawLine(
        nodeRelationship.src!.nodePositionComponent!.center.toOffset(),
        nodeRelationship.dst!.nodePositionComponent!.center.toOffset(),
        paint);
  }
}
