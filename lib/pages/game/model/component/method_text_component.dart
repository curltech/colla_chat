import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/type_node_component.dart';
import 'package:colla_chat/pages/game/model/widget/method_edit_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class MethodTextComponent extends TextComponent
    with TapCallbacks, DoubleTapCallbacks, HasGameRef<ModelFlameGame> {
  static final TextPaint normal = TextPaint(
    style: const TextStyle(
      color: Colors.black,
      fontSize: 12.0,
    ),
  );

  static const double contentHeight = 20;

  Method method;

  MethodTextComponent(
    this.method, {
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

  Future<void> onDelete() async {
    List<Method> methods = (parent as MethodAreaComponent).methods;
    methods.remove(method);
    removeFromParent();
    (parent as MethodAreaComponent).updateSize();
  }

  Future<void> onUpdate() async {
    text = '${method.scope} ${method.returnType}:${method.name}';
  }
}

class MethodAreaComponent extends RectangleComponent
    with TapCallbacks, DoubleTapCallbacks, HasGameRef<ModelFlameGame> {
  final List<Method> methods;

  MethodAreaComponent({
    required Vector2 position,
    required this.methods,
  }) : super(
          position: position,
          paint: TypeNodeComponent.fillPaint,
        );

  @override
  Future<void> onLoad() async {
    width = Project.nodeWidth;
    updateSize();
    if (methods.isNotEmpty) {
      for (int i = 0; i < methods.length; ++i) {
        Method method = methods[i];
        Vector2 position = Vector2(0, i * MethodTextComponent.contentHeight);
        add(MethodTextComponent(method, position: position));
      }
    }
    size.addListener(() {
      (parent as TypeNodeComponent).updateSize();
    });
  }

  updateSize() {
    if (methods.isEmpty) {
      height = MethodTextComponent.contentHeight;
    } else {
      height = MethodTextComponent.contentHeight * methods.length;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(const Offset(0, 0), const Offset(Project.nodeWidth, 0),
        NodeFrameComponent.strokePaint);
    super.render(canvas);
  }

  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    indexWidgetProvider.push('method_edit');
  }

  Future<void> onAdd(Method method) async {
    if (!methods.contains(method)) {
      methods.add(method);
    }
    methods.add(method);
    Vector2 position =
        Vector2(0, methods.length * MethodTextComponent.contentHeight);
    MethodTextComponent methodTextComponent =
        MethodTextComponent(method, position: position);
    method.methodTextComponent = methodTextComponent;
    add(methodTextComponent);
    updateSize();
  }
}
