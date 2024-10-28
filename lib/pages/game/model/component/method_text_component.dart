import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_position_component.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class MethodTextComponent extends TextComponent
    with TapCallbacks, HasGameRef<ModelFlameGame> {
  static final TextPaint normal = TextPaint(
    style: TextStyle(
      color: BasicPalette.black.color,
      fontSize: 14.0,
      shadows: const [
        Shadow(color: Colors.red, offset: Offset(2, 2), blurRadius: 2),
        Shadow(color: Colors.yellow, offset: Offset(4, 4), blurRadius: 4),
      ],
    ),
  );

  static const double contentHeight = 30;

  /// String text = '${method.scope} ${method.returnType}:${method.name}';
  MethodTextComponent(
    Method method, {
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  }) : super(
            text: '${method.scope} ${method.returnType}:${method.name}',
            textRenderer: normal) {
    size = Vector2(Project.nodeWidth, contentHeight);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {}
}

class MethodAreaComponent extends RectangleComponent
    with TapCallbacks, HasGameRef<ModelFlameGame> {
  final List<Method> methods;

  MethodAreaComponent({
    required Vector2 position,
    required Vector2 size,
    required this.methods,
  }) : super(
          position: position,
          paint: NodePositionComponent.fillPaint,
        );

  @override
  Future<void> onLoad() async {
    width = Project.nodeWidth;
    height = MethodTextComponent.contentHeight;
    if (methods.isNotEmpty) {
      height = MethodTextComponent.contentHeight * methods.length;
      for (int i = 0; i < methods.length; ++i) {
        Method method = methods[i];
        Vector2 position = Vector2(0, i * MethodTextComponent.contentHeight);
        add(MethodTextComponent(method, position: position));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(Offset(0, 0), Offset(Project.nodeWidth, 0),
        NodePositionComponent.strokePaint);
    super.render(canvas);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {}
}
