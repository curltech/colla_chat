import 'dart:async';
import 'dart:math';
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
  static final TextPaint metaTextPaint = TextPaint(
    style: const TextStyle(
      color: Colors.black,
      fontSize: 10.0,
      decoration: TextDecoration.underline,
    ),
  );

  final ModelNode modelNode;
  Anchor textAlign;
  late final TextBoxComponent nodeTextComponent;
  TextBoxComponent? metaNodeTextComponent;

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
    ModelNode? metaModelNode = modelNode.metaModelNode;
    if (metaModelNode != null) {
      metaNodeTextComponent = TextBoxComponent(
        text: metaModelNode.name,
        textRenderer: metaTextPaint,
        position: Vector2(0, 0),
        size: size,
        align: Anchor.topCenter,
        priority: 2,
        boxConfig: const TextBoxConfig(),
      );
      add(metaNodeTextComponent!);
    }

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
    Paint? fillPaint;
    Paint? strokePaint;
    int? fillColor = modelNode.fillColor;
    if (fillColor != null) {
      fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Color(fillColor);
    }
    int? strokeColor = modelNode.strokeColor;
    if (strokeColor != null) {
      strokePaint = Paint()
        ..color = Color(strokeColor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
    }

    String shapeType = modelNode.shapeType ?? ShapeType.rect.name;
    if (shapeType == ShapeType.rect.name) {
      Rect rect = Rect.fromLTWH(0, 0, width, height);
      if (fillPaint != null) {
        canvas.drawRect(rect, fillPaint);
      }
      if (strokePaint != null) {
        canvas.drawRect(rect, strokePaint);
      }
    }
    if (shapeType == ShapeType.rrect.name) {
      Rect rect = Rect.fromLTWH(0, 0, width, height);
      RRect rrect = RRect.fromRectXY(rect, 16.0, 16.0);
      if (fillPaint != null) {
        canvas.drawRRect(rrect, fillPaint);
      }
      if (strokePaint != null) {
        canvas.drawRRect(rrect, strokePaint);
      }
    }
    if (shapeType == ShapeType.circle.name) {
      if (fillPaint != null) {
        canvas.drawCircle(Offset(width / 2, height / 2), height / 2, fillPaint);
      }
      if (strokePaint != null) {
        Rect rect = Rect.fromLTWH(0, 0, width, height);
        canvas.drawRect(rect, strokePaint);
      }
    }
    if (shapeType == ShapeType.oval.name) {
      Rect rect = Rect.fromLTWH(0, 0, width, height);
      if (fillPaint != null) {
        canvas.drawOval(rect, fillPaint);
      }
      if (strokePaint != null) {
        canvas.drawOval(rect, strokePaint);
      }
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
      path.moveTo(0, height / 2);
      path.lineTo(width / 2, 0);
      path.lineTo(width, height / 2);
      path.lineTo(width / 2, height);
      path.lineTo(0, height / 2);
      if (fillPaint != null) {
        canvas.drawPath(path, fillPaint);
      }
      if (strokePaint != null) {
        canvas.drawPath(path, strokePaint);
      }
    }
    if (shapeType == ShapeType.hexagonal.name) {
      Path path = Path();
      path.moveTo(width / 3, 0);
      path.lineTo(width * 2 / 3, 0);
      path.lineTo(width, height / 2);
      path.lineTo(width * 2 / 3, height);
      path.lineTo(width / 3, height);
      path.lineTo(0, height / 2);
      path.lineTo(width / 3, 0);
      if (fillPaint != null) {
        canvas.drawPath(path, fillPaint);
      }
      if (strokePaint != null) {
        canvas.drawPath(path, strokePaint);
      }
    }
    if (shapeType == ShapeType.octagonal.name) {
      Path path = Path();
      path.moveTo(width / 3, 0);
      path.lineTo(width * 2 / 3, 0);
      path.lineTo(width, height / 3);
      path.lineTo(width, height * 2 / 3);
      path.lineTo(width * 2 / 3, height);
      path.lineTo(width / 3, height);
      path.lineTo(0, height * 2 / 3);
      path.lineTo(0, height / 3);
      path.lineTo(width / 3, 0);
      if (fillPaint != null) {
        canvas.drawPath(path, fillPaint);
      }
      if (strokePaint != null) {
        canvas.drawPath(path, strokePaint);
      }
    }
    if (shapeType == ShapeType.arcrect.name) {
      Path path = Path();
      path.moveTo(height / 2, 0);
      path.lineTo(width - height / 2, 0);
      path.arcToPoint(Offset(width - height / 2, height),
          radius: Radius.circular(height / 2));
      path.lineTo(height / 2, height);
      path.arcToPoint(Offset(height / 2, 0),
          radius: Radius.circular(height / 2));
      if (fillPaint != null) {
        canvas.drawPath(path, fillPaint);
      }
      if (strokePaint != null) {
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  @override
  Future<void> onUpdate() async {
    nodeTextComponent.text = modelNode.name;
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    (parent as NodeFrameComponent).onTapDown(event);
  }

  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    modelProjectController.selectedSrcModelNode.value = modelNode;
    indexWidgetProvider.push('node_edit');
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    (parent as NodeFrameComponent).onDragUpdate(event);
  }
}
