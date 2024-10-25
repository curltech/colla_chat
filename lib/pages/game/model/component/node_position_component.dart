import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/attribute_text_component.dart';
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
  static final strokePaint = BasicPalette.black.paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  late Rect strokeRect;

  final double padding;
  final double imageSize;
  final Node node;

  NodePositionComponent({
    required Vector2 position,
    required Vector2 size,
    required this.padding,
    required this.node,
    required this.imageSize,
  }) : super(
          position: position,
          size: size,
          paint: fillPaint,
        );

  TextBoxComponent _buildNodeTextComponent({
    required String text,
    Vector2? size,
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
        size: size,
        scale: scale,
        angle: angle,
        position: Vector2(30, 0),
        // anchor: anchor ?? Anchor.topCenter,
        // align: align ?? Anchor.center,
        priority: 2,
        boxConfig: boxConfig,
        textRenderer: textPaint);
  }

  PolygonComponent _buildDivideComponent(Vector2 start, Vector2 end) {
    return PolygonComponent([
      start,
      end,
    ], paint: strokePaint);
  }

  @override
  Future<void> onLoad() async {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    strokeRect = Rect.fromLTWH(0, 0, width, height);
    size.addListener(() {
      strokeRect = Rect.fromLTWH(0, 0, width, height);
    });
    if (node.image != null) {
      SpriteComponent spriteComponent =
          SpriteComponent(sprite: Sprite(node.image!));
      add(spriteComponent);
    } else {
      if (node is ModelNode) {
        ModelNode metaModelNode = node as ModelNode;
        add(_buildNodeTextComponent(
          text: metaModelNode.name,
        ));
        add(AttributeAreaComponent(
            position: Vector2(0, 50),
            size: Vector2(120, 40),
            attributes: metaModelNode.attributes));
        add(MethodAreaComponent(
            position: Vector2(0, 100),
            size: Vector2(120, 20),
            methods: metaModelNode.methods));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(strokeRect, strokePaint);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {}

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    node.x = position.toOffset().dx;
    node.y = position.toOffset().dy;
  }
}
