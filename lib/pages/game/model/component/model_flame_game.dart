import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/node_relationship_component.dart';
import 'package:colla_chat/pages/game/model/component/subject_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

/// [ModelFlameGame] 使用flame engine渲染画布和所有的节点
/// FlameGame包含world对象，camera表示看world的方式
/// camera包含backdrop，viewport和viewfinder，Viewport也是组件，可以加入其他组件
/// Viewfinder控制viewport的缩放，角度，backdrop是背景组件
/// Camera.follow()，Camera.stop()，Camera.moveBy()，Camera.moveTo()，Camera.setBounds()
class ModelFlameGame extends FlameGame
    with
        TapCallbacks,
        ScrollDetector,
        ScaleDetector,
        HasCollisionDetection,
        HasKeyboardHandlerComponents {
  ModelFlameGame();

  static const zoomPerScrollUnit = 0.02;

  late double startZoom;

  late SubjectComponent subjectComponent;

  // @override
  // bool debugMode = true;

  @override
  Color backgroundColor() {
    return Colors.white.withAlpha(0);
  }

  double clampZoom(double zoom, {num lowerLimit = 0.05, num upperLimit = 3.0}) {
    if (zoom < 0.05) {
      zoom = 0.05;
    }
    if (zoom > 3.0) {
      zoom = 3.0;
    }
    return zoom;
  }

  @override
  void onScroll(PointerScrollInfo info) {
    double zoom = camera.viewfinder.zoom +
        info.scrollDelta.global.y.sign * zoomPerScrollUnit;

    camera.viewfinder.zoom = clampZoom(zoom);
  }

  @override
  void onScaleStart(_) {
    startZoom = camera.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final currentScale = info.scale.global;
    if (!currentScale.isIdentity()) {
      var zoom = startZoom * currentScale.y;
      zoom = clampZoom(zoom);
      camera.viewfinder.zoom = zoom;
    } else {
      final delta = info.delta.global;
      camera.viewfinder.position.translate(-delta.x, -delta.y);
    }
  }

  /// 渲染画布上的所有节点和线
  void _renderProject() {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    var subjects = project.subjects.values.toList();
    for (int i = 0; i < subjects.length; ++i) {
      Subject subject = subjects[i];
      renderSubject(subject);
      _renderRelationship(subject);
    }
  }

  void renderSubject(Subject subject) {
    subjectComponent = SubjectComponent(subject);
    subject.subjectComponent = subjectComponent;
    world.add(subjectComponent);
    Iterable<ModelNode> modelNodes = subject.modelNodes.values;
    for (ModelNode modelNode in modelNodes) {
      NodeFrameComponent nodeFrameComponent = NodeFrameComponent(
        modelNode,
        subject,
        position: Vector2(modelNode.x!, modelNode.y!),
      );
      modelNode.nodeFrameComponent = nodeFrameComponent;
      world.add(nodeFrameComponent);
    }
  }

  /// 渲染线
  void _renderRelationship(Subject subject) {
    for (NodeRelationship nodeRelationship in subject.relationships.values) {
      NodeRelationshipComponent nodeRelationshipComponent =
          NodeRelationshipComponent(nodeRelationship: nodeRelationship);
      if (nodeRelationship.src == null || nodeRelationship.dst == null) {
        return;
      }
      nodeRelationship.nodeRelationshipComponent = nodeRelationshipComponent;
      world.add(nodeRelationshipComponent);
    }
  }

  /// camera移到当前主题的位置
  void moveTo() {
    String? current = modelProjectController.currentSubjectName.value;
    if (current == null) {
      return;
    }
    Subject? subject = modelProjectController.project.value?.subjects[current];
    if (subject == null) {
      return;
    }

    /// viewport的位置
    Offset center = subject.rect.center;
    camera.moveTo(Vector2(center.dx, center.dy));
  }

  @override
  Future<void> onLoad() async {
    _renderProject();
    moveTo();

    return super.onLoad();
  }

  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    moveTo();
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    modelProjectController.selectedSrcModelNode.value = null;
    modelProjectController.selectedDstModelNode.value = null;
    modelProjectController.selectedRelationship.value = null;
    Vector2 globalPosition = event.devicePosition;
    Vector2 widgetPosition = event.canvasPosition;
    Vector2 localPosition = event.localPosition;
    Vector2 worldPosition = camera.globalToLocal(widgetPosition);
    Vector2 cameraPosition = camera.viewfinder.position;

    bool canAddSubject = modelProjectController.canAddSubject.value;
    if (canAddSubject) {
      String? subjectName = await DialogUtil.showTextFormField(
          title: 'New subject',
          content: 'Please input new subject name',
          tip: 'unknown');
      if (subjectName != null) {
        Subject subject =
            Subject(subjectName, x: worldPosition.x, y: worldPosition.y);
        modelProjectController.currentSubjectName.value = subject.name;
        project.subjects[subject.name] = subject;
        renderSubject(subject);
        moveTo();
      }
      modelProjectController.canAddSubject.value = false;
    }

    ModelNode? addModelNode = modelProjectController.canAddModelNode.value;
    if (addModelNode != null) {
      Subject? subject = modelProjectController.getCurrentSubject();
      if (subject == null) {
        return;
      }
      String? nodeName = await DialogUtil.showTextFormField(
          title: 'New node',
          content: 'Please input new node name',
          tip: 'unknown');
      if (nodeName != null) {
        ModelNode modelNode = ModelNode(
          name: nodeName,
          nodeType: addModelNode.nodeType,
          shapeType: addModelNode.shapeType,
          metaId: addModelNode.id,
          fillColor: addModelNode.fillColor,
          strokeColor: addModelNode.strokeColor,
        );
        if (modelNode.nodeType == NodeType.remark.name ||
            modelNode.nodeType == NodeType.type.name) {
          modelNode.content = addModelNode.content;
        }
        modelNode.image = addModelNode.image;
        modelNode.metaModelNode = addModelNode;

        modelNode.x = worldPosition.x;
        modelNode.y = worldPosition.y;
        modelNode.width = addModelNode.width;
        modelNode.height = addModelNode.height;
        subject.modelNodes[modelNode.id] = modelNode;
        NodeFrameComponent nodeFrameComponent = NodeFrameComponent(
          modelNode,
          subject,
          position: Vector2(modelNode.x!, modelNode.y!),
        );
        modelNode.nodeFrameComponent = nodeFrameComponent;
        world.add(nodeFrameComponent);

        subjectComponent.onUpdate();
      }
      modelProjectController.canAddModelNode.value = null;
    }
  }

  void addRelationship(RelationshipType relationshipType) {
    ModelNode? srcModelNode = modelProjectController.selectedSrcModelNode.value;
    ModelNode? dstModelNode = modelProjectController.selectedDstModelNode.value;
    if (srcModelNode != null && dstModelNode != null) {
      NodeRelationship nodeRelationship = NodeRelationship(
          srcModelNode, dstModelNode,
          relationshipType: relationshipType.name);
      if (dstModelNode.nodeType == NodeType.remark.name) {
        nodeRelationship.relationshipType = RelationshipType.reference.name;
      }
      modelProjectController.getCurrentSubject()!.add(nodeRelationship);
      NodeRelationshipComponent nodeRelationshipComponent =
          NodeRelationshipComponent(nodeRelationship: nodeRelationship);
      if (nodeRelationship.src != null && nodeRelationship.dst != null) {
        nodeRelationship.nodeRelationshipComponent = nodeRelationshipComponent;
        world.add(nodeRelationshipComponent);
      }
      modelProjectController.selectedSrcModelNode.value = null;
      modelProjectController.selectedDstModelNode.value = null;
    }
  }
}
