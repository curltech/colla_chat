import 'dart:async';
import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// 在shape节点写文本
class ShapeNodeComponent extends PositionComponent
    with
        ModelNodeComponent,
        TapCallbacks,
        DragCallbacks,
        HasGameRef<ModelFlameGame> {
  static final TextPaint normalTextPaint = TextPaint(
    style: const TextStyle(
      color: Colors.black,
      fontSize: 16.0,
    ),
  );

  final ModelNode modelNode;
  Anchor textAlign;
  late final TextBoxComponent nodeTextComponent;

  ShapeNodeComponent(
    this.modelNode, {
    super.position,
    this.textAlign = Anchor.center,
    super.scale,
    super.angle,
    Vector2? nodeSize,
  }) : super(size: nodeSize ?? Vector2(Project.nodeWidth, Project.nodeHeight));

  @override
  Future<void> onLoad() async {
    nodeTextComponent = TextBoxComponent(
      text: modelNode.name,
      textRenderer: normalTextPaint,
      size: size,
      position: Vector2(0, 0),
      align: textAlign,
      priority: 2,
      boxConfig: const TextBoxConfig(),
    );
    add(nodeTextComponent);
    size.addListener(() {
      (parent as NodeFrameComponent).updateSize();
    });
    (parent as NodeFrameComponent).updateSize();
  }

  @override
  void render(Canvas canvas) {
    String nodeType = modelNode.nodeType;
    if (nodeType != NodeType.shape.name) {
      return;
    }
    String shapeType = modelNode.shapeType ?? ShapeType.rect.name;
    if (shapeType == ShapeType.rect.name) {
      // Rect rect = Rect.fromLTWH(0, 0, width, height);
      // canvas.drawRect(rect, NodeFrameComponent.strokePaint);
    }
    if (shapeType == ShapeType.rrect.name) {
      Rect rect = Rect.fromLTWH(0, 0, width, height);
      RRect rrect = RRect.fromRectXY(rect, 8.0, 8.0);
      canvas.drawRRect(rrect, NodeFrameComponent.strokePaint);
    }
    if (shapeType == ShapeType.circle.name) {
      canvas.drawCircle(Offset(width / 2, height / 2), width / 2,
          NodeFrameComponent.strokePaint);
    }
    if (shapeType == ShapeType.oval.name) {
      Rect rect = Rect.fromLTWH(0, 0, width, height);
      canvas.drawOval(rect, NodeFrameComponent.strokePaint);
    }
    if (shapeType == ShapeType.paragraph.name) {
      ParagraphStyle style =
          ParagraphStyle(textAlign: TextAlign.start, fontSize: 10.0);
      ParagraphBuilder paragraphBuilder = ParagraphBuilder(style);
      paragraphBuilder.addText(modelNode.content ?? '');
      Paragraph paragraph = paragraphBuilder.build();
      canvas.drawParagraph(paragraph, const Offset(0, 0));
    }
    if (shapeType == ShapeType.diamond.name) {
      Path path = Path();
      path.moveTo(width / 2, 0);
      path.lineTo(0, height / 2);
      path.lineTo(width / 2, height);
      path.moveTo(width / 2, 0);
      path.lineTo(width, height);
      path.lineTo(width / 2, height);
      canvas.drawPath(path, NodeFrameComponent.strokePaint);
    }
  }

  Future<void> onUpdate() async {
    nodeTextComponent.text = modelNode.name;
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    (parent as NodeFrameComponent).onTapDown(event);
  }

  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    modelProjectController.selectedModelNode.value = modelNode;
    indexWidgetProvider.push('node_edit');
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    (parent as NodeFrameComponent).onDragUpdate(event);
  }
}
