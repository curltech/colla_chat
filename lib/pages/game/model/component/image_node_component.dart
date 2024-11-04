import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// 在image节点写文本
class ImageNodeComponent extends PositionComponent
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

  ImageNodeComponent(
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
    DialogUtil.info(content: 'ImageNodeComponent onTapDown');
  }

  @override
  Future<void> onLoad() async {
    if (modelNode.image == null) {
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
