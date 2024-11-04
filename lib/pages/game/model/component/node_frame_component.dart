import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_relationship_component.dart';
import 'package:colla_chat/pages/game/model/component/type_node_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// [NodeFrameComponent] 节点框架组件，保存的位置和大小，是flame引擎的位置组件，可以在画布上拖拽
/// 内部可以包含type，image，shape，remark等各种类型的组件
class NodeFrameComponent extends RectangleComponent
    with DragCallbacks, TapCallbacks, HasGameRef<ModelFlameGame> {
  static final fillPaint = Paint()
    ..color = myself.primary
    ..style = PaintingStyle.fill;
  static final strokePaint = BasicPalette.black.paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final selectedStrokePaint = BasicPalette.yellow.paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  late Rect strokeRect;
  final ModelNode modelNode;

  NodeFrameComponent({
    required Vector2 position,
    required this.modelNode,
  }) : super(
          position: position,
        ) {
    paint = fillPaint;
  }

  @override
  Future<void> onLoad() async {
    String nodeType = modelNode.nodeType;
    if (nodeType == NodeType.type.name) {
      width = Project.nodeWidth;
      TypeNodeComponent typeNodeComponent =
          TypeNodeComponent(modelNode: modelNode, position: position);
      add(typeNodeComponent);
    }

    strokeRect = Rect.fromLTWH(-1, -1, width + 2, height + 2);
    size.addListener(() {
      strokeRect = Rect.fromLTWH(-1, -1, width + 2, height + 2);
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (modelProjectController.selected.value == modelNode) {
      canvas.drawRect(strokeRect, selectedStrokePaint);
    } else {
      canvas.drawRect(strokeRect, strokePaint);
    }
  }

  /// 单击根据状态决定是否连线或者选择高亮
  @override
  Future<void> onTapDown(TapDownEvent event) async {
    if (modelProjectController.selected.value == null) {
      modelProjectController.selected.value = modelNode;
    } else {
      if (modelProjectController.addRelationshipStatus.value) {
        NodeRelationship nodeRelationship =
            NodeRelationship(modelProjectController.selected.value, modelNode);
        modelProjectController.getCurrentSubject()!.add(nodeRelationship);
        NodeRelationshipComponent nodeRelationshipComponent =
            NodeRelationshipComponent(nodeRelationship: nodeRelationship);
        if (nodeRelationship.src != null && nodeRelationship.dst != null) {
          nodeRelationship.nodeRelationshipComponent =
              nodeRelationshipComponent;
          game.add(nodeRelationshipComponent);
        }
        modelProjectController.addRelationshipStatus.value = false;

        modelProjectController.selected.value = null;
      } else {
        modelProjectController.selected.value = modelNode;
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (position.x + event.localDelta.x <= 1500 &&
        position.x + event.localDelta.x >= 0 &&
        position.y + event.localDelta.y < 1500 &&
        position.y + event.localDelta.y >= 0) {
      position += event.localDelta;
      modelNode.x = position.toOffset().dx;
      modelNode.y = position.toOffset().dy;
    }
  }
}
