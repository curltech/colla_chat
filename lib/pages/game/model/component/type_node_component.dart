import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/attribute_text_component.dart';
import 'package:colla_chat/pages/game/model/component/method_text_component.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// [TypeNodeComponent] type节点，用于类图，包含属性和方法
class TypeNodeComponent extends RectangleComponent
    with
        ModelNodeComponent,
        TapCallbacks,
        DragCallbacks,
        HasGameRef<ModelFlameGame> {
  static final fillPaint = Paint()
    ..color = myself.primary
    ..style = PaintingStyle.fill;

  static const double headHeight = 30;

  final double padding = 10.0;
  final ModelNode modelNode;
  late final TextBoxComponent nodeNameComponent;
  late final AttributeAreaComponent attributeAreaComponent;
  late final MethodAreaComponent methodAreaComponent;

  TypeNodeComponent(
    this.modelNode, {
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
    attributeAreaComponent = AttributeAreaComponent(
        position: Vector2(0, headHeight), attributes: modelNode.attributes);
    add(attributeAreaComponent);
    methodAreaComponent = MethodAreaComponent(
        position: Vector2(0, headHeight + calAttributeHeight()),
        methods: modelNode.methods);
    add(methodAreaComponent);
    size.addListener(() {
      (parent as NodeFrameComponent).updateSize();
    });
    updateSize();
  }

  Future<void> onUpdate() async {
    nodeNameComponent.text = modelNode.name;
  }

  double calAttributeHeight() {
    ModelNode modelNode = this.modelNode;
    double attributeHeight = AttributeTextComponent.contentHeight;
    if (modelNode.attributes.isNotEmpty) {
      attributeHeight =
          modelNode.attributes.length * AttributeTextComponent.contentHeight;
    }

    return attributeHeight;
  }

  double calMethodHeight() {
    double methodHeight = MethodTextComponent.contentHeight;
    if (modelNode.methods.isNotEmpty) {
      methodHeight =
          modelNode.methods.length * MethodTextComponent.contentHeight;
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
    (parent as NodeFrameComponent).onTapDown(event);
  }

  /// 长按弹出节点编辑窗口
  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    modelProjectController.selectedModelNode.value = modelNode;
    indexWidgetProvider.push('node_edit');
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    (parent as NodeFrameComponent).onDragUpdate(event);
  }
}
