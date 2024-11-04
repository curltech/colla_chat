import 'dart:async';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// 在remark节点写文本
class RemarkNodeComponent extends TextBoxComponent
    with TapCallbacks, HasGameRef<ModelFlameGame> {
  static final TextPaint normal = TextPaint(
    style: TextStyle(
      color: BasicPalette.black.color,
      fontSize: 12.0,
    ),
  );

  double contentHeight = 100.0;
  final ModelNode modelNode;

  RemarkNodeComponent(
    this.modelNode, {
    super.align = Anchor.center,
    super.position,
    super.scale,
    super.angle,
    super.anchor = Anchor.topLeft,
    super.children,
    super.priority,
    super.key,
  }) : super(text: modelNode.content, textRenderer: normal) {
    size = Vector2(Project.nodeWidth, contentHeight);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    DialogUtil.info(content: 'ImageNodeComponent onTapDown');
  }

  @override
  Future<void> onLoad() async {}

  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return ModelNodeEditWidget(
        modelNode: modelNode,
      );
    });
    text = modelNode.content ?? '';
  }
}
