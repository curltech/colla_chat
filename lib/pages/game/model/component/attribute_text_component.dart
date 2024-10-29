import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/method_text_component.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_position_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/tool/dialog_util.dart';
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

  static const double contentHeight = 30;

  /// String text = '${attribute.scope} ${attribute.dataType}:${attribute.name}';
  AttributeTextComponent(
    Attribute attribute, {
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  }) : super(
            text: '${attribute.scope} ${attribute.dataType}:${attribute.name}',
            textRenderer: normal) {
    size = Vector2(Project.nodeWidth, contentHeight);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    DialogUtil.info(content: 'AttributeTextComponent onTapDown');
  }
}

class AttributeAreaComponent extends RectangleComponent
    with TapCallbacks, HasGameRef<ModelFlameGame> {
  final List<Attribute> attributes;

  AttributeAreaComponent({
    required Vector2 position,
    required this.attributes,
  }) : super(
          position: position,
          paint: NodePositionComponent.fillPaint,
        );

  @override
  Future<void> onLoad() async {
    width = Project.nodeWidth;
    height = AttributeTextComponent.contentHeight;
    if (attributes.isNotEmpty) {
      height = AttributeTextComponent.contentHeight * attributes.length;
      for (int i = 0; i < attributes.length; ++i) {
        Attribute attribute = attributes[i];
        Vector2 position = Vector2(0, i * AttributeTextComponent.contentHeight);
        add(AttributeTextComponent(attribute, position: position));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(const Offset(0, 0), const Offset(Project.nodeWidth, 0),
        NodePositionComponent.strokePaint);
    super.render(canvas);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    DialogUtil.info(content: 'AttributeAreaComponent onTapDown');
  }
}
