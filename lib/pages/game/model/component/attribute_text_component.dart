import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/type_node_component.dart';
import 'package:colla_chat/pages/game/model/widget/attribute_edit_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class AttributeTextComponent extends TextComponent
    with TapCallbacks, HoverCallbacks, HasGameRef<ModelFlameGame> {
  static final TextPaint normal = TextPaint(
    style: const TextStyle(
      color: Colors.black,
      fontSize: 12.0,
    ),
  );

  static const double contentHeight = 20;

  Attribute attribute;

  AttributeTextComponent(
    this.attribute, {
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

  /// 单击询问是否删除属性
  @override
  Future<void> onTapDown(TapDownEvent event) async {
    List<ActionData> actionData = [
      ActionData(
          label: 'Add', tooltip: 'Add attribute', icon: const Icon(Icons.add)),
      ActionData(
          label: 'Delete',
          tooltip: 'Delete attribute',
          icon: const Icon(Icons.delete_outline)),
      ActionData(
          label: 'Update',
          tooltip: 'Update attribute',
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
    (parent as AttributeAreaComponent).onAdd();
  }

  Future<void> _onDelete() async {
    bool? success = await DialogUtil.confirm(
        content: 'Do you confirm to delete this attribute:${attribute.name}');
    if (success != null && success) {
      List<Attribute> attributes =
          (parent as AttributeAreaComponent).attributes;
      attributes.remove(attribute);
      removeFromParent();
      (parent as AttributeAreaComponent).updateSize();
    }
  }

  Future<void> _onUpdate() async {
    Attribute? a =
        await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return AttributeEditWidget(
        attribute: attribute,
      );
    });
    if (a != null) {
      text = '${attribute.scope} ${attribute.dataType}:${attribute.name}';
    }
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
          paint: TypeNodeComponent.fillPaint,
        );

  @override
  Future<void> onLoad() async {
    width = Project.nodeWidth;
    updateSize();
    if (attributes.isNotEmpty) {
      for (int i = 0; i < attributes.length; ++i) {
        Attribute attribute = attributes[i];
        Vector2 position = Vector2(0, i * AttributeTextComponent.contentHeight);
        add(AttributeTextComponent(attribute, position: position));
      }
    }
    size.addListener(() {
      (parent as TypeNodeComponent).updateSize();
    });
  }

  updateSize() {
    if (attributes.isEmpty) {
      height = AttributeTextComponent.contentHeight;
    } else {
      height = AttributeTextComponent.contentHeight * attributes.length;
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
    Attribute attribute = Attribute('unknownAttribute');
    Attribute? a =
        await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return AttributeEditWidget(
        attribute: attribute,
      );
    });
    if (a != null) {
      attributes.add(attribute);
      Vector2 position = Vector2(
          0, (attributes.length - 1) * AttributeTextComponent.contentHeight);
      add(AttributeTextComponent(attribute, position: position));
      updateSize();
    }
  }
}
