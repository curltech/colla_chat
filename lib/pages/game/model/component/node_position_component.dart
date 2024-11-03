import 'dart:typed_data';
import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/attribute_text_component.dart';
import 'package:colla_chat/pages/game/model/component/node_relationship_component.dart';
import 'package:colla_chat/pages/game/model/component/method_text_component.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_text_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// [NodePositionComponent] 保存节点的位置和大小，是flame引擎的位置组件，可以在画布上拖拽
class NodePositionComponent extends RectangleComponent
    with DragCallbacks, TapCallbacks, HasGameRef<ModelFlameGame> {
  static final fillPaint = Paint()
    ..color = myself.primary
    ..style = PaintingStyle.fill;

  // static final selectedFillPaint = BasicPalette.yellow.paint()
  //   ..style = PaintingStyle.fill;
  static final strokePaint = BasicPalette.black.paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final selectedStrokePaint = BasicPalette.yellow.paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  late Rect strokeRect;
  static const double headHeight = 30;

  final double padding;
  final double imageSize;
  final ModelNode modelNode;
  late final TextBoxComponent nodeNameComponent;
  late final AttributeAreaComponent attributeAreaComponent;
  late final MethodAreaComponent methodAreaComponent;

  NodePositionComponent({
    required Vector2 position,
    required this.padding,
    required this.modelNode,
    required this.imageSize,
  }) : super(
          position: position,
        ) {
    paint = fillPaint;
  }

  TextBoxComponent _buildNodeNameComponent({
    required String text,
    Vector2? scale,
    double? angle,
    Anchor? anchor,
    Anchor? align,
  }) {
    final textPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.black.color,
        fontSize: 14.0,
      ),
    );
    TextBoxConfig boxConfig = const TextBoxConfig();

    return TextBoxComponent(
        text: text,
        size: Vector2(Project.nodeWidth, headHeight),
        scale: scale,
        angle: angle,
        position: Vector2(0, 0),
        anchor: anchor ?? Anchor.topLeft,
        align: align ?? Anchor.center,
        priority: 2,
        boxConfig: boxConfig,
        textRenderer: textPaint);
  }

  @override
  Future<void> onLoad() async {
    if (modelNode.imageContent != null) {
      NodeTextComponent nodeTextComponent = NodeTextComponent(modelNode);
      add(nodeTextComponent);
    } else {
      width = Project.nodeWidth;
      nodeNameComponent = _buildNodeNameComponent(
        text: modelNode.name,
      );
      add(nodeNameComponent);
      attributeAreaComponent = AttributeAreaComponent(
          position: Vector2(0, headHeight), attributes: modelNode.attributes);
      add(attributeAreaComponent);

      methodAreaComponent = MethodAreaComponent(
          position: Vector2(0, headHeight + calAttributeHeight()),
          methods: modelNode.methods);
      add(methodAreaComponent);

      updateHeight();
    }

    strokeRect = Rect.fromLTWH(-1, -1, width + 2, height + 2);
    size.addListener(() {
      strokeRect = Rect.fromLTWH(-1, -1, width + 2, height + 2);
    });
  }

  double calAttributeHeight() {
    double attributeHeight =
        modelNode.attributes.length * AttributeTextComponent.contentHeight;
    if (modelNode.attributes.isEmpty) {
      attributeHeight = AttributeTextComponent.contentHeight;
    }

    return attributeHeight;
  }

  double calMethodHeight() {
    double methodHeight =
        modelNode.methods.length * MethodTextComponent.contentHeight;
    if (modelNode.methods.isEmpty) {
      methodHeight = MethodTextComponent.contentHeight;
    }

    return methodHeight;
  }

  updateHeight() {
    height = headHeight + calAttributeHeight() + calMethodHeight();
    methodAreaComponent.position =
        Vector2(0, headHeight + calAttributeHeight());
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
        NodeRelationship nodeRelationship = NodeRelationship(
            modelProjectController.selected.value,
            modelNode,
            RelationshipType.association.name);
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

  /// 长按弹出节点编辑窗口
  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    ModelNode? m =
        await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return ModelNodeEditWidget(
        modelNode: modelNode,
      );
    });
    if (m != null) {
      nodeNameComponent.text = modelNode.name;
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
