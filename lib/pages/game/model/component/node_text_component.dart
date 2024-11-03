import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/method_text_component.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_position_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/attribute_edit_widget.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class NodeTextComponent extends PositionComponent
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

  /// String text = '${attribute.scope} ${attribute.dataType}:${attribute.name}';
  NodeTextComponent(
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
    DialogUtil.info(content: 'NodeTextComponent onTapDown');
  }

  @override
  Future<void> onLoad() async {
    if (modelNode.imageContent == null) {
      final image = await game.images
          .fromBase64('${modelNode.name}.png', modelNode.imageContent!);
      modelNode.image = image;
    }
    if (modelNode.image != null) {
      SpriteComponent spriteComponent =
          SpriteComponent(sprite: Sprite(modelNode.image!));
      add(spriteComponent);
    }
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
  Future<void> onLongTapDown(TapDownEvent event) async {
    await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return ModelNodeEditWidget(
        modelNode: modelNode,
      );
    });
    nodeTextComponent.text = modelNode.name;
  }
}
