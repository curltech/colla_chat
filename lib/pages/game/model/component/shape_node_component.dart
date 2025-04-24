import 'dart:async';
import 'dart:ui' as ui;

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/plugin/painter/image_recorder.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// 在shape节点写文本
class ShapeNodeComponent extends PositionComponent
    with
        ModelNodeComponent,
        TapCallbacks,
        DragCallbacks,
        HasGameReference<ModelFlameGame> {
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
  }) : super(size: Vector2(modelNode.width, modelNode.height));

  @override
  Future<void> onLoad() async {
    ModelNode? metaModelNode = modelNode.metaModelNode;
    if (metaModelNode != null) {
      if (modelNode.width > 150 && modelNode.height > 90) {
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
    int? fillColor = modelNode.fillColor ?? myself.primaryColor.value32bit;
    fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(fillColor);
    int? fillColor1 = modelNode.strokeColor ?? Colors.white.value32bit;
    Paint? fillPaint1 = Paint()
      ..color = Color(fillColor1)
      ..style = PaintingStyle.fill;
    int? strokeColor = modelNode.strokeColor ?? Colors.white.value32bit;
    strokePaint = Paint()
      ..color = Color(strokeColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    /// 如果是元模型项目需要截取节点的图像
    ImageRecorder? imageRecorder;
    Project? project = modelProjectController.project.value;
    if (project != null && project.meta && modelNode.image == null) {
      imageRecorder = ImageRecorder();
    }

    String shapeType = modelNode.shapeType ?? ShapeType.rect.name;
    if (shapeType == ShapeType.rect.name) {
      Rect rect = Rect.fromLTWH(0, 0, width, height);
      canvas.drawRect(rect, fillPaint);
      imageRecorder?.recorderCanvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
      imageRecorder?.recorderCanvas.drawRect(rect, strokePaint);
    }
    if (shapeType == ShapeType.rrect.name) {
      Rect rect = Rect.fromLTWH(0, 0, width, height);
      RRect rrect = RRect.fromRectXY(rect, 16.0, 16.0);
      canvas.drawRRect(rrect, fillPaint);
      imageRecorder?.recorderCanvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);
      imageRecorder?.recorderCanvas.drawRRect(rrect, strokePaint);
    }
    if (shapeType == ShapeType.circle.name) {
      canvas.drawCircle(Offset(width / 2, height / 2), height / 2, fillPaint);
      imageRecorder?.recorderCanvas
          .drawCircle(Offset(width / 2, height / 2), height / 2, fillPaint);
      canvas.drawCircle(Offset(width / 2, height / 2), height / 2, strokePaint);
      imageRecorder?.recorderCanvas
          .drawCircle(Offset(width / 2, height / 2), height / 2, strokePaint);
    }
    if (shapeType == ShapeType.oval.name) {
      Rect rect = Rect.fromLTWH(0, 0, width, height);
      canvas.drawOval(rect, fillPaint);
      imageRecorder?.recorderCanvas.drawOval(rect, fillPaint);
      canvas.drawOval(rect, strokePaint);
      imageRecorder?.recorderCanvas.drawOval(rect, strokePaint);
    }
    if (shapeType == ShapeType.dcircle.name) {
      canvas.drawCircle(Offset(width / 2, height / 2), height / 2, fillPaint);
      imageRecorder?.recorderCanvas
          .drawCircle(Offset(width / 2, height / 2), height / 2, fillPaint);
      canvas.drawCircle(Offset(width / 2, height / 2), height / 2, strokePaint);
      imageRecorder?.recorderCanvas
          .drawCircle(Offset(width / 2, height / 2), height / 2, strokePaint);
      canvas.drawCircle(Offset(width / 2, height / 2),
          height / 2 - modelNode.width / 5, fillPaint1);
      imageRecorder?.recorderCanvas.drawCircle(Offset(width / 2, height / 2),
          height / 2 - modelNode.width / 5, fillPaint1);
    }
    if (shapeType == ShapeType.paragraph.name) {
      ui.ParagraphStyle style =
          ui.ParagraphStyle(textAlign: TextAlign.start, fontSize: 10.0);
      ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(style);
      paragraphBuilder.addText(modelNode.content ?? '');
      ui.Paragraph paragraph = paragraphBuilder.build();
      canvas.drawParagraph(paragraph, const Offset(0, 0));
      imageRecorder?.recorderCanvas
          .drawParagraph(paragraph, const Offset(0, 0));
    }
    if (shapeType == ShapeType.diamond.name) {
      Path path = Path();
      path.moveTo(0, height / 2);
      path.lineTo(width / 2, 0);
      path.lineTo(width, height / 2);
      path.lineTo(width / 2, height);
      path.lineTo(0, height / 2);
      canvas.drawPath(path, fillPaint);
      imageRecorder?.recorderCanvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
      imageRecorder?.recorderCanvas.drawPath(path, strokePaint);
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
      canvas.drawPath(path, fillPaint);
      imageRecorder?.recorderCanvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
      imageRecorder?.recorderCanvas.drawPath(path, strokePaint);
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
      canvas.drawPath(path, fillPaint);
      imageRecorder?.recorderCanvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
      imageRecorder?.recorderCanvas.drawPath(path, strokePaint);
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
      canvas.drawPath(path, fillPaint);
      imageRecorder?.recorderCanvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
      imageRecorder?.recorderCanvas.drawPath(path, strokePaint);
    }

    ui.Image? image = imageRecorder?.toImage(width.toInt(), height.toInt());
    if (image != null) {
      modelNode.image = image;
      ImageUtil.toBase64String(image).then((data) {
        modelNode.content = data;
      });
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
