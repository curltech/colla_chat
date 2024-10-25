import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
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

  /// String text = '${method.scope} ${method.returnType}:${method.name}';
  MethodTextComponent(
    Method method, {
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  }) : super(
            text: '${method.scope} ${method.returnType}:${method.name}',
            textRenderer: normal);

  @override
  Future<void> onTapDown(TapDownEvent event) async {}
}

class MethodAreaComponent extends RectangleComponent
    with TapCallbacks, HasGameRef<ModelFlameGame> {
  static final nodePaint = BasicPalette.black.paint()
    ..style = PaintingStyle.stroke;

  final List<Method> methods;

  MethodAreaComponent({
    required Vector2 position,
    required Vector2 size,
    required this.methods,
  }) : super(
          position: position,
          size: size,
          paint: nodePaint,
        );

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < methods.length; ++i) {
      Method method = methods[i];
      Vector2 position = Vector2(0, i * 50);
      add(MethodTextComponent(method, position: position));
    }
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {}
}
