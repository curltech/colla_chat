import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/component/method_text_component.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class AttributeTextComponent extends TextComponent
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

  /// String text = '${attribute.scope} ${attribute.dataType}:${attribute.name}';
  AttributeTextComponent(
    Attribute attribute, {
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  }) : super(
            text: '${attribute.scope} ${attribute.dataType}:${attribute.name}',
            textRenderer: normal);

  @override
  Future<void> onTapDown(TapDownEvent event) async {}
}

class AttributeAreaComponent extends RectangleComponent
    with TapCallbacks, HasGameRef<ModelFlameGame> {
  static final strokePaint = BasicPalette.black.paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  late Rect strokeRect;

  final List<Attribute> attributes;

  AttributeAreaComponent({
    required Vector2 position,
    required Vector2 size,
    required this.attributes,
  }) : super(
          position: position,
          size: size,
        );

  @override
  Future<void> onLoad() async {
    strokeRect = Rect.fromLTWH(0, 0, width, height);
    size.addListener(() {
      strokeRect = Rect.fromLTWH(0, 0, width, height);
    });
    for (int i = 0; i < attributes.length; ++i) {
      Attribute attribute = attributes[i];
      Vector2 position = Vector2(0, i * 50);
      add(AttributeTextComponent(attribute, position: position));
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(strokeRect, strokePaint);
    super.render(canvas);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {}
}
