import 'dart:async';
import 'dart:ui' as ui;

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// 在image节点写文本
class ImageNodeComponent extends PositionComponent
    with
        ModelNodeComponent,
        TapCallbacks,
        DragCallbacks,
        HasGameRef<ModelFlameGame> {
  static final TextPaint normalTextPaint = TextPaint(
    style: const TextStyle(
      color: Colors.black,
      fontSize: 16.0,
    ),
  );

  final ModelNode modelNode;
  Anchor textAlign;
  late final TextBoxComponent nodeTextComponent;
  late final SpriteComponent spriteComponent;

  ImageNodeComponent(
    this.modelNode, {
    this.textAlign = Anchor.center,
    super.position,
    super.scale,
    super.angle,
    super.anchor = Anchor.topLeft,
    super.children,
    super.priority,
    Vector2? nodeSize,
  }) : super(size: nodeSize ?? Vector2(Project.nodeWidth, Project.nodeHeight));

  @override
  Future<void> onLoad() async {
    await loadImage();
    add(spriteComponent);
    nodeTextComponent = TextBoxComponent(
      text: modelNode.name,
      textRenderer: normalTextPaint,
      position: Vector2(0, 0),
      align: textAlign,
      size: size,
      priority: 2,
      boxConfig: const TextBoxConfig(),
    );
    add(nodeTextComponent);
    size.addListener(() {
      (parent as NodeFrameComponent).updateSize();
    });
    (parent as NodeFrameComponent).updateSize();
  }

  loadImage() async {
    if (modelNode.image == null) {
      ui.Image? image;
      if (modelNode.content != null) {
        image = await game.images
            .fromBase64('${modelNode.name}.png', modelNode.content!);
      }
      image ??= await game.images.load('colla.png');
      modelNode.image = image;
    }
    if (modelNode.image != null) {
      spriteComponent =
          SpriteComponent(sprite: Sprite(modelNode.image!), size: size);
    }
  }

  @override
  Future<void> onUpdate() async {
    remove(spriteComponent);
    loadImage();
    add(spriteComponent);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    (parent as NodeFrameComponent).onTapDown(event);
  }

  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    modelProjectController.selectedSrcModelNode.value = modelNode;
    indexWidgetProvider.push('node_edit');
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    (parent as NodeFrameComponent).onDragUpdate(event);
  }
}
