import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/attribute_text_component.dart';
import 'package:colla_chat/pages/game/model/component/line_component.dart';
import 'package:colla_chat/pages/game/model/component/method_text_component.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// [NodePositionComponent] 保存节点的位置和大小，是flame引擎的位置组件，可以在画布上拖拽
class NodePositionComponent extends RectangleComponent
    with DragCallbacks, TapCallbacks, HasGameRef<ModelFlameGame> {
  static final fillPaint = BasicPalette.cyan.paint()
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

  TextBoxComponent _buildNodeTextComponent({
    required String text,
    Vector2? scale,
    double? angle,
    Anchor? anchor,
    Anchor? align,
  }) {
    final textPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.black.color,
        fontSize: 16.0,
        // shadows: const [
        //   Shadow(color: Colors.red, offset: Offset(2, 2), blurRadius: 2),
        //   Shadow(color: Colors.yellow, offset: Offset(4, 4), blurRadius: 4),
        // ],
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
    width = Project.nodeWidth;
    if (modelNode.image != null) {
      SpriteComponent spriteComponent =
          SpriteComponent(sprite: Sprite(modelNode.image!));
      add(spriteComponent);
    } else {
      add(_buildNodeTextComponent(
        text: modelNode.name,
      ));
      int attributeLength =
          modelNode.attributes.isNotEmpty ? modelNode.attributes.length : 1;
      double attributeHeight =
          attributeLength * AttributeTextComponent.contentHeight;
      add(AttributeAreaComponent(
          position: Vector2(0, headHeight), attributes: modelNode.attributes));
      int methodLength =
          modelNode.methods.isNotEmpty ? modelNode.methods.length : 1;
      double methodHeight = methodLength * MethodTextComponent.contentHeight;
      add(MethodAreaComponent(
          position: Vector2(0, headHeight + attributeHeight),
          methods: modelNode.methods));

      height = headHeight + attributeHeight + methodHeight;
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

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    if (modelProjectController.selected.value == null) {
      modelProjectController.selected.value = modelNode;
    } else {
      if (modelProjectController.addRelationshipStatus.value &&
          modelProjectController.selected.value != modelNode) {
        NodeRelationship nodeRelationship = NodeRelationship(
            modelProjectController.selected.value,
            modelNode,
            RelationshipType.association);
        modelProjectController
            .getCurrentSubject()!
            .relationships
            .add(nodeRelationship);
        LineComponent lineComponent =
            LineComponent(nodeRelationship: nodeRelationship);
        nodeRelationship.lineComponent = lineComponent;
        modelProjectController.addRelationshipStatus.value = false;
        game.add(lineComponent);
      }
      modelProjectController.selected.value = null;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    modelNode.x = position.toOffset().dx;
    modelNode.y = position.toOffset().dy;
  }
}
