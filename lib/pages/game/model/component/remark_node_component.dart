import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// 在remark节点写文本
class RemarkNodeComponent extends TextBoxComponent
    with
        ModelNodeComponent,
        TapCallbacks,
        DragCallbacks,
        HasGameRef<ModelFlameGame> {
  static final TextPaint normalTextPaint = TextPaint(
    style: TextStyle(
      color: BasicPalette.black.color,
      fontSize: 12.0,
    ),
  );

  final ModelNode modelNode;

  RemarkNodeComponent(
    this.modelNode, {
    super.align,
    Vector2? nodeSize,
    double? timePerChar,
    double? margins,
  }) : super(
            text: modelNode.content ?? '',
            textRenderer: normalTextPaint,
            boxConfig: TextBoxConfig(
              timePerChar: timePerChar ?? 0.05,
              growingBox: true,
              margins: EdgeInsets.all(margins ?? 10),
            ),
            size: nodeSize ?? Vector2(Project.nodeWidth, Project.nodeHeight));

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    (parent as NodeFrameComponent).onTapDown(event);
  }

  @override
  Future<void> onLoad() async {
    size.addListener(() {
      (parent as NodeFrameComponent).updateSize();
    });
    return super.onLoad();
  }

  @override
  Future<void> onUpdate() async {
    text = modelNode.content ?? '';
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
