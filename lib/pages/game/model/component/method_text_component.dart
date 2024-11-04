import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/type_node_component.dart';
import 'package:colla_chat/pages/game/model/widget/method_edit_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class MethodTextComponent extends TextComponent
    with TapCallbacks, DoubleTapCallbacks, HasGameRef<ModelFlameGame> {
  static final TextPaint normal = TextPaint(
    style: TextStyle(
      color: BasicPalette.black.color,
      fontSize: 12.0,
    ),
  );

  static const double contentHeight = 20;

  Method method;

  /// String text = '${method.scope} ${method.returnType}:${method.name}';
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

  _onAction(int index, String name, {String? value}) async {
    switch (name) {
      case 'Add':
        _onAdd();
        break;
      case 'Delete':
        _onDelete();
        break;
      case 'Update':
        _onUpdate();
        break;
      default:
        break;
    }
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    List<ActionData> actionData = [
      ActionData(
          label: 'Add', tooltip: 'Add method', icon: const Icon(Icons.add)),
      ActionData(
          label: 'Delete',
          tooltip: 'Delete method',
          icon: const Icon(Icons.delete_outline)),
      ActionData(
          label: 'Update',
          tooltip: 'Update method',
          icon: const Icon(Icons.update)),
    ];

    await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return DataActionCard(
        actions: actionData,
        width: appDataProvider.secondaryBodyWidth,
        height: 100,
        onPressed: (int index, String label, {String? value}) {
          Navigator.pop(context);
          _onAction(index, label, value: value);
        },
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        crossAxisCount: 3,
      );
    });
  }

  Future<void> _onAdd() async {
    (parent as MethodAreaComponent).onAdd();
  }

  Future<void> _onDelete() async {
    bool? success = await DialogUtil.confirm(
        content: 'Do you confirm to delete this method:${method.name}');
    if (success != null && success) {
      List<Method> methods = (parent as MethodAreaComponent).methods;
      methods.remove(method);
      removeFromParent();
      (parent as MethodAreaComponent).updateHeight();
    }
  }

  Future<void> _onUpdate() async {
    Attribute? a =
        await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return MethodEditWidget(
        method: method,
      );
    });
    if (a != null) {
      text = '${method.scope} ${method.returnType}:${method.name}';
    }
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
          paint: NodeFrameComponent.fillPaint,
        );

  @override
  Future<void> onLoad() async {
    width = Project.nodeWidth;
    updateHeight();
    if (methods.isNotEmpty) {
      for (int i = 0; i < methods.length; ++i) {
        Method method = methods[i];
        Vector2 position = Vector2(0, i * MethodTextComponent.contentHeight);
        add(MethodTextComponent(method, position: position));
      }
    }
    size.addListener(() {
      (parent as TypeNodeComponent).updateHeight();
    });
  }

  updateHeight() {
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
  Future<void> onTapDown(TapDownEvent event) async {
    onAdd();
  }

  Future<void> onAdd() async {
    Method method = Method('unknownMethod');
    Method? m =
        await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return MethodEditWidget(
        method: method,
      );
    });
    if (m != null) {
      methods.add(method);
      Vector2 position =
          Vector2(0, methods.length * MethodTextComponent.contentHeight);
      MethodTextComponent methodTextComponent =
          MethodTextComponent(method, position: position);
      add(methodTextComponent);
      updateHeight();
    }
  }
}
