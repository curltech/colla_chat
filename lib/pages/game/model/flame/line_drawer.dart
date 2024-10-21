import 'package:colla_chat/pages/game/model/flame/model_canvas_controller.dart';
import 'package:colla_chat/pages/game/model/flame/model_canvas_flame.dart';
import 'package:colla_chat/pages/game/model/flame/node.dart';
import 'package:colla_chat/pages/game/model/flame/node_position_component.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// [LineDrawer] 在src节点和所有的关系节点之间画关系的连线
class LineDrawer extends PositionComponent with HasGameRef<ModelCanvasFlame> {
  final ModelCanvasController modelCanvasController;

  LineDrawer({required this.modelCanvasController, required this.node})
      : super();

  /// [Node] draws line to its relationship nodes，this node is src node
  final Node node;

  @override
  Future<void> onLoad() async {}

  @override
  void render(Canvas canvas) {
    List<NodeRelationship>? ships =
        modelCanvasController.nodeRelationships[node];
    if (ships == null) {
      return;
    }

    /// loop all relationship from graph node
    for (NodeRelationship ship in ships) {
      /// if node items is null breaks
      if (!modelCanvasController.nodePositionComponents
          .containsKey(node.name)) {
        break;
      }

      /// if dst item is  null then continue the loop
      if (!modelCanvasController.nodePositionComponents
          .containsKey(ship.dst.name)) {
        continue;
      }
      Paint paint = BasicPalette.red.paint();
      if (game.onDrawLine != null) {
        // get the pain from user implementation
        paint = game.onDrawLine!(ship.dst, node) ?? BasicPalette.red.paint();
      }

      /// draw a line from parent to children
      NodePositionComponent nodePositionComponent =
          modelCanvasController.nodePositionComponents[node.name]!;
      NodePositionComponent dstNodePositionComponent =
          modelCanvasController.nodePositionComponents[ship.dst.name]!;
      canvas.drawLine(
          dstNodePositionComponent.spriteComponent.center.toOffset(),
          nodePositionComponent.spriteComponent.center.toOffset(),
          paint);
    }
  }
}
