import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/attribute_text_component.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/node_relationship_component.dart';
import 'package:colla_chat/pages/game/model/component/method_text_component.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/model_node_edit_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// [TypeNodeComponent] type节点，用于类图，包含属性和方法
class TypeNodeComponent extends RectangleComponent
    with TapCallbacks, HasGameRef<ModelFlameGame> {
  static final fillPaint = Paint()
    ..color = myself.primary
    ..style = PaintingStyle.fill;

  static const double headHeight = 30;

  final double padding = 10.0;
  final ModelNode modelNode;
  late final TextBoxComponent nodeNameComponent;
  late final AttributeAreaComponent attributeAreaComponent;
  late final MethodAreaComponent methodAreaComponent;

  TypeNodeComponent({
    required this.modelNode,
    double? width,
    double? height,
  }) : super(paint: fillPaint) {
    width = width ?? Project.nodeWidth;
    height = height ?? Project.nodeHeight;
    size = Vector2(width, height);
  }

  TextBoxComponent _buildNodeNameComponent({
    required String text,
    double? angle,
    Vector2? scale,
    Anchor? anchor,
    Anchor? align,
  }) {
    final textPaint = TextPaint(
      style: TextStyle(
        color: BasicPalette.black.color,
        fontSize: 14.0,
      ),
    );

    return TextBoxComponent(
        text: text,
        size: Vector2(Project.nodeWidth, headHeight),
        scale: scale,
        angle: angle,
        position: Vector2(0, 0),
        anchor: anchor ?? Anchor.topLeft,
        align: align ?? Anchor.center,
        priority: 2,
        boxConfig: const TextBoxConfig(),
        textRenderer: textPaint);
  }

  @override
  Future<void> onLoad() async {
    nodeNameComponent = _buildNodeNameComponent(
      text: modelNode.name,
    );
    add(nodeNameComponent);
    if (modelNode.attributes != null) {
      attributeAreaComponent = AttributeAreaComponent(
          position: Vector2(0, headHeight), attributes: modelNode.attributes!);
      add(attributeAreaComponent);
    }
    if (modelNode.attributes != null) {
      methodAreaComponent = MethodAreaComponent(
          position: Vector2(0, headHeight + calAttributeHeight()),
          methods: modelNode.methods!);
      add(methodAreaComponent);
    }
    size.addListener(() {
      (parent as NodeFrameComponent).updateSize();
    });
    updateSize();
  }

  double calAttributeHeight() {
    double attributeHeight = AttributeTextComponent.contentHeight;
    if (modelNode.attributes != null && modelNode.attributes!.isNotEmpty) {
      attributeHeight =
          modelNode.attributes!.length * AttributeTextComponent.contentHeight;
    }

    return attributeHeight;
  }

  double calMethodHeight() {
    double methodHeight = MethodTextComponent.contentHeight;
    if (modelNode.methods != null && modelNode.methods!.isNotEmpty) {
      methodHeight =
          modelNode.methods!.length * MethodTextComponent.contentHeight;
    }

    return methodHeight;
  }

  updateSize() {
    height = headHeight + calAttributeHeight() + calMethodHeight();
    methodAreaComponent.position =
        Vector2(0, headHeight + calAttributeHeight());
  }

  /// 单击根据状态决定是否连线或者选择高亮
  @override
  Future<void> onTapDown(TapDownEvent event) async {
    if (modelProjectController.selected.value == null) {
      modelProjectController.selected.value = modelNode;
    } else {
      if (modelProjectController.addRelationshipStatus.value) {
        NodeRelationship nodeRelationship =
            NodeRelationship(modelProjectController.selected.value, modelNode);
        modelProjectController.getCurrentSubject()!.add(nodeRelationship);
        NodeRelationshipComponent nodeRelationshipComponent =
            NodeRelationshipComponent(nodeRelationship: nodeRelationship);
        if (nodeRelationship.src != null && nodeRelationship.dst != null) {
          nodeRelationship.nodeRelationshipComponent =
              nodeRelationshipComponent;
          game.add(nodeRelationshipComponent);
        }
        modelProjectController.addRelationshipStatus.value = false;

        modelProjectController.selected.value = null;
      } else {
        modelProjectController.selected.value = modelNode;
      }
    }
  }

  /// 长按弹出节点编辑窗口
  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    ModelNode? m =
        await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return ModelNodeEditWidget(
        modelNode: modelNode,
      );
    });
    if (m != null) {
      nodeNameComponent.text = modelNode.name;
    }
  }
}
