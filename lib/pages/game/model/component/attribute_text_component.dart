import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/type_node_component.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class AttributeTextComponent extends TextComponent
    with
        ModelNodeComponent,
        TapCallbacks,
        HoverCallbacks,
        HasGameRef<ModelFlameGame> {
  static final TextPaint normal = TextPaint(
    style: const TextStyle(
      color: Colors.black,
      fontSize: 12.0,
    ),
  );

  static const double contentHeight = 20;

  Attribute attribute;

  double nodeWidth;

  AttributeTextComponent(
    this.attribute,
    this.nodeWidth, {
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
    size = Vector2(nodeWidth, contentHeight);
  }

  Future<void> onDelete() async {
    List<Attribute> attributes = (parent as AttributeAreaComponent).attributes;
    attributes.remove(attribute);
    removeFromParent();
    (parent as AttributeAreaComponent).updateSize();
  }

  @override
  Future<void> onUpdate() async {
    text = '${attribute.scope} ${attribute.dataType}:${attribute.name}';
  }
}

class AttributeAreaComponent extends RectangleComponent
    with TapCallbacks, HasGameRef<ModelFlameGame> {
  final List<Attribute> attributes;

  AttributeAreaComponent({
    required Vector2 position,
    required Vector2 size,
    required this.attributes,
  }) : super(
          position: position,
          size: size,
          paint: TypeNodeComponent.fillPaint,
        );

  @override
  Future<void> onLoad() async {
    updateSize();
    if (attributes.isNotEmpty) {
      for (int i = 0; i < attributes.length; ++i) {
        Attribute attribute = attributes[i];
        Vector2 position = Vector2(0, i * AttributeTextComponent.contentHeight);
        add(AttributeTextComponent(attribute, width, position: position));
      }
    }
    size.addListener(() {
      (parent as TypeNodeComponent).updateSize();
    });
  }

  void updateSize() {
    if (attributes.isEmpty) {
      height = AttributeTextComponent.contentHeight;
    } else {
      height = AttributeTextComponent.contentHeight * attributes.length;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
        const Offset(0, 0), Offset(width, 0), NodeFrameComponent.strokePaint);
    super.render(canvas);
  }

  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    indexWidgetProvider.push('attribute_edit');
  }

  Future<void> onAdd(Attribute attribute) async {
    if (!attributes.contains(attribute)) {
      attributes.add(attribute);
    }
    Vector2 position = Vector2(
        0, (attributes.length - 1) * AttributeTextComponent.contentHeight);
    AttributeTextComponent attributeTextComponent =
        AttributeTextComponent(attribute, width, position: position);
    attribute.attributeTextComponent = attributeTextComponent;
    add(attributeTextComponent);
    updateSize();
  }
}
