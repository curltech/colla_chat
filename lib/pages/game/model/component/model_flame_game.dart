import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/pages/game/model/component/line_component.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/node_position_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
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
        HasKeyboardHandlerComponents,
        HasGameRef {
  ModelFlameGame()
      : super(
          camera: CameraComponent(),
        );

  @override
  Color backgroundColor() {
    return Colors.grey;
  }

  /// 渲染画布上的所有节点和线
  void _renderProject() {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    for (Subject subject in project.subjects) {
      _renderSubject(project, subject);
      _renderRelationship(project, subject);
    }
  }

  double get totalWidth {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return 0.0;
    }
    double totalWidth = project.nodeWidth * 7 + 100;

    return totalWidth;
  }

  void _renderSubject(Project project, Subject subject) {
    double i = 0;
    double j = 0;

    List<Node> modelNodes = subject.modelNodes;
    for (Node node in modelNodes) {
      double nodei = i;
      double nodej = j;
      NodePositionComponent nodePositionComponent = NodePositionComponent(
        size: Vector2((project.nodeWidth + (project.nodePadding * 2)),
            (project.nodeWidth + (project.nodePadding * 2))),
        position: Vector2(nodej, nodei),
        padding: project.nodePadding,
        node: node,
        imageSize: project.nodeWidth,
      );
      world.add(nodePositionComponent);

      if (j < totalWidth - (project.nodeWidth + (project.nodePadding * 2))) {
        j = j + (project.nodeWidth + (project.nodePadding * 2));
      } else {
        i = i + (project.nodeWidth + (project.nodePadding * 2));
        j = 0;
      }
    }
  }

  /// 渲染线
  void _renderRelationship(Project project, Subject subject) {
    for (NodeRelationship nodeRelationship in subject.relationships) {
      LineComponent lineComponent =
          LineComponent(nodeRelationship: nodeRelationship);
      world.add(lineComponent);
    }
  }

  @override
  Future<void> onLoad() async {
    /// 设置画布的边界使得摄像头不可以超出范围
    camera.setBounds(
        Rectangle.fromPoints(Vector2(0, 0), Vector2(totalWidth, totalWidth)));

    /// render the nodes in the screen
    _renderProject();
  }

  @override
  void update(double dt) {
    super.update(dt);

    /// update the zoom value based on the controllers input
    camera.viewfinder.zoom = 1;
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
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
        modelProjectController.project.value?.subjects.add(subject);
      }
      modelProjectController.addSubjectStatus.value = false;
    }
    if (modelProjectController.addNodeStatus.value) {
      String? nodeName = await DialogUtil.showTextFormField(
          title: 'New node',
          content: 'Please input new node name',
          tip: 'unknown');
      if (nodeName != null) {
        ModelNode metaModelNode = ModelNode(name: nodeName);
        metaModelNode.x = localPosition.x;
        metaModelNode.y = localPosition.y;
        Subject? subject = modelProjectController.getCurrentSubject();
        if (subject != null) {
          subject.modelNodes.add(metaModelNode);
        }
      }
      modelProjectController.addNodeStatus.value = false;
    }
  }
}
