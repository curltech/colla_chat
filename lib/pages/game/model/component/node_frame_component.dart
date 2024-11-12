import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/pages/game/model/component/image_node_component.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_relationship_component.dart';
import 'package:colla_chat/pages/game/model/component/remark_node_component.dart';
import 'package:colla_chat/pages/game/model/component/shape_node_component.dart';
import 'package:colla_chat/pages/game/model/component/subject_component.dart';
import 'package:colla_chat/pages/game/model/component/type_node_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

mixin ModelNodeComponent on PositionComponent {
  Future<void> onUpdate() async {}
}

/// [NodeFrameComponent] 节点框架组件，保存的位置和大小，是flame引擎的位置组件，可以在画布上拖拽
/// 内部可以包含type，image，shape，remark等各种类型的组件
class NodeFrameComponent extends RectangleComponent
    with
        DragCallbacks,
        TapCallbacks,
        HoverCallbacks,
        HasGameRef<ModelFlameGame> {
  static final fillPaint = Paint()
    ..color = Colors.white.withOpacity(0)
    ..style = PaintingStyle.fill;
  static final strokePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final selectedStrokePaint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  late Rect strokeRect;
  final ModelNode modelNode;
  final Subject subject;
  ModelNodeComponent? child;

  NodeFrameComponent(
    this.modelNode,
    this.subject, {
    required Vector2 position,
  }) : super(position: position, paint: fillPaint);

  @override
  Future<void> onLoad() async {
    String nodeType = modelNode.nodeType;
    width = Project.nodeWidth;
    if (nodeType == NodeType.type.name) {
      child = TypeNodeComponent(modelNode);
      add(child!);
    } else if (nodeType == NodeType.image.name) {
      child = ImageNodeComponent(modelNode);
      add(child!);
    } else if (nodeType == NodeType.shape.name) {
      child = ShapeNodeComponent(modelNode);
      add(child!);
    } else if (nodeType == NodeType.remark.name) {
      child = RemarkNodeComponent(
        modelNode,
        align: Anchor.topLeft,
      );
      add(child!);
    }

    /// 绘制框架组件的边框
    strokeRect = Rect.fromLTWH(-1, -1, width + 2, height + 2);
    size.addListener(() {
      strokeRect = Rect.fromLTWH(-1, -1, width + 2, height + 2);
      modelNode.width = width;
      modelNode.height = height;
      SubjectComponent? subjectComponent = subject.subjectComponent;
      subjectComponent?.onUpdate();
    });
    position.addListener(() {
      SubjectComponent? subjectComponent = subject.subjectComponent;
      subjectComponent?.onUpdate();
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (isHovered ||
        modelProjectController.selectedSrcModelNode.value == modelNode ||
        modelProjectController.selectedDstModelNode.value == modelNode) {
      canvas.drawRect(strokeRect, selectedStrokePaint);
    } else {
      canvas.drawRect(strokeRect, strokePaint);
    }
  }

  /// 子组件的大小发生变化，调用此方法更新框架组件的大小
  updateSize() {
    if (child != null) {
      height = child!.height;
      width = child!.width;
    }
  }

  /// 单击根据状态决定是否连线或者选择高亮
  @override
  Future<void> onTapDown(TapDownEvent event) async {
    if (modelProjectController.selectedSrcModelNode.value == null) {
      modelProjectController.selectedSrcModelNode.value = modelNode;
    } else {
      if (modelProjectController.selectedDstModelNode.value == null) {
        modelProjectController.selectedDstModelNode.value = modelNode;
      } else {
        modelProjectController.selectedSrcModelNode.value =
            modelProjectController.selectedDstModelNode.value;
        modelProjectController.selectedDstModelNode.value = modelNode;
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (event.localDelta.x <= 500 &&
        event.localDelta.x >= -500 &&
        event.localDelta.y < 500 &&
        event.localDelta.y >= -500) {
      position += event.localDelta;
      modelNode.x = position.toOffset().dx;
      modelNode.y = position.toOffset().dy;
    }
  }
}
