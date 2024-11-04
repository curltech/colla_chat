import 'dart:async';
import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// 在shape节点写文本
class ShapeNodeComponent extends PositionComponent
    with TapCallbacks, HasGameRef<ModelFlameGame> {
  static final TextPaint normal = TextPaint(
    style: TextStyle(
      color: BasicPalette.black.color,
      fontSize: 12.0,
    ),
  );

  final ModelNode modelNode;
  Anchor align;
  late final TextBoxComponent nodeTextComponent;

  ShapeNodeComponent(
    this.modelNode, {
    this.align = Anchor.center,
    super.position,
    super.scale,
    super.angle,
    super.anchor = Anchor.topLeft,
    super.children,
    super.priority,
    super.key,
  });

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    DialogUtil.info(content: 'ImageNodeComponent onTapDown');
  }

  @override
  Future<void> onLoad() async {
    nodeTextComponent = TextBoxComponent(
      text: modelNode.name,
      textRenderer: normal,
      position: Vector2(0, 0),
      anchor: anchor,
      align: align,
      priority: 2,
      boxConfig: const TextBoxConfig(),
    );
    add(nodeTextComponent);
  }

  @override
  void render(Canvas canvas) {
    String nodeType = modelNode.nodeType;
    if (nodeType != NodeType.shape.name) {
      return;
    }
    String shapeType = modelNode.shapeType ?? ShapeType.rect.name;
    if (shapeType == ShapeType.rect.name) {
      Rect rect = Rect.fromLTWH(0, 0, width, height);
      canvas.drawRect(rect, NodeFrameComponent.strokePaint);
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

  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return ModelNodeEditWidget(
        modelNode: modelNode,
      );
    });
    nodeTextComponent.text = modelNode.name;
  }
}
