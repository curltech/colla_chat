import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/node_relationship_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

/// [ModelFlameGame] 使用flame engine渲染画布和所有的节点
class ModelFlameGame extends FlameGame
    with
        TapCallbacks,
        DoubleTapCallbacks,
        ScrollDetector,
        ScaleDetector,
        HasCollisionDetection,
        HasKeyboardHandlerComponents {
  ModelFlameGame()
      : super(
          camera: CameraComponent(),
        );

  // @override
  // bool debugMode = true;

  @override
  Color backgroundColor() {
    return Colors.white.withOpacity(0.0);
  }

  /// 渲染画布上的所有节点和线
  void _renderProject() {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    for (Subject subject in project.subjects.values) {
      _renderSubject(project, subject);
      _renderRelationship(project, subject);
    }
  }

  double get totalWidth {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return 0.0;
    }
    double totalWidth = Project.nodeWidth * 7 + 100;

    return totalWidth;
  }

  void _renderSubject(Project project, Subject subject) {
    double i = 0;
    double j = 0;
    double nodeWidth = Project.nodeWidth;
    Iterable<ModelNode> modelNodes = subject.modelNodes.values;
    for (ModelNode modelNode in modelNodes) {
      double? nodeX = modelNode.x ?? i;
      double? nodeY = modelNode.y ?? j;
      NodeFrameComponent nodeFrameComponent = NodeFrameComponent(
        position: Vector2(nodeX, nodeY),
        modelNode: modelNode,
      );
      modelNode.nodeFrameComponent = nodeFrameComponent;
      add(nodeFrameComponent);

      if (i < totalWidth - nodeWidth) {
        i = i + nodeWidth;
      } else {
        j = j + nodeWidth;
        i = 0;
      }
    }
  }

  /// 渲染线
  void _renderRelationship(Project project, Subject subject) {
    for (NodeRelationship nodeRelationship in subject.relationships.values) {
      NodeRelationshipComponent nodeRelationshipComponent =
          NodeRelationshipComponent(nodeRelationship: nodeRelationship);
      if (nodeRelationship.src == null || nodeRelationship.dst == null) {
        return;
      }
      nodeRelationship.nodeRelationshipComponent = nodeRelationshipComponent;
      add(nodeRelationshipComponent);
    }
  }

  @override
  Future<void> onLoad() async {
    /// 设置画布的边界使得摄像头不可以超出范围
    // camera.setBounds(
    //     Rectangle.fromPoints(Vector2(0, 0), Vector2(totalWidth, totalWidth)));

    /// render the nodes in the screen
    _renderProject();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    /// update the zoom value based on the controllers input
    // camera.viewfinder.zoom = 1;
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    modelProjectController.selectedModelNode.value = null;
    Vector2 localPosition = event.localPosition;
    if (modelProjectController.addSubjectStatus.value) {
      String? subjectName = await DialogUtil.showTextFormField(
          title: 'New subject',
          content: 'Please input new subject name',
          tip: 'unknown');
      if (subjectName != null) {
        Subject subject = Subject(subjectName);
        subject.x = localPosition.x;
        subject.y = localPosition.y;
        modelProjectController.currentSubjectName.value = subject.name;
        project.subjects[subject.name] = subject;
      }
      modelProjectController.addSubjectStatus.value = false;
    }
    NodeType? addNodeStatus = modelProjectController.addNodeStatus.value;
    if (addNodeStatus != null) {
      Subject? subject = modelProjectController.getCurrentSubject();
      if (subject == null) {
        return;
      }
      String? nodeName = await DialogUtil.showTextFormField(
          title: 'New node',
          content: 'Please input new node name',
          tip: 'unknown');
      if (nodeName != null) {
        ModelNode modelNode =
            ModelNode(name: nodeName, nodeType: addNodeStatus.name);
        modelNode.x = localPosition.x;
        modelNode.y = localPosition.y;
        subject.modelNodes[modelNode.id] = modelNode;
        NodeFrameComponent nodeFrameComponent = NodeFrameComponent(
          position: Vector2(modelNode.x!, modelNode.y!),
          modelNode: modelNode,
        );
        modelNode.nodeFrameComponent = nodeFrameComponent;
        add(nodeFrameComponent);
      }
      modelProjectController.addNodeStatus.value = null;
    }
  }
}
