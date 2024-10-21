import 'package:colla_chat/pages/game/model/flame/canvas_component.dart';
import 'package:colla_chat/pages/game/model/flame/focus_point.dart';
import 'package:colla_chat/pages/game/model/flame/line_drawer.dart';
import 'package:colla_chat/pages/game/model/flame/model_canvas_controller.dart';
import 'package:colla_chat/pages/game/model/flame/node.dart';
import 'package:colla_chat/pages/game/model/flame/node_position_component.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as mat;

/// [ModelCanvasFlame] 使用flame engine渲染画布和所有的节点
class ModelCanvasFlame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents, HasGameRef {
  ModelCanvasFlame({
    required this.nodePadding,
    required this.nodeSize,
    required this.context,
    required this.isDebug,
    required this.onDrawLine,
    required this.modelCanvasController,
    required this.flameBackgroundColor,
    required this.pixelRatio,
    required this.onNodeTap,
  }) : super(
          camera: CameraComponent(),
        );

  /// [isDebug] 缺省false，调试模式将显示wireframe
  @override
  bool get debugMode => isDebug;

  /// [pixelRatio] gives the resolution to the widget after rendering
  final double? pixelRatio;

  /// [context]so widget can be rendered
  final BuildContext context;

  /// [focusPoint] 画布的中心
  late FocusPointImpl focusPoint;

  /// [nodeSize] 画布上所有节点占用的大小
  final double nodeSize;

  /// [nodePadding] 两个节点之间的距离
  final double nodePadding;

  /// [isDebug] 调试模式将显示wireframe
  final bool isDebug;

  /// 两个节点之间的关系的连线
  final Paint? Function(Node lineFrom, Node lineTo)? onDrawLine;

  /// [modelCanvasController] 管理整个画布的状态
  final ModelCanvasController modelCanvasController;

  /// [flameBackgroundColor] sets background color to the canvas
  final Color? flameBackgroundColor;

  /// [onNodeTap] 点击节点的触发事件
  final Function(Node)? onNodeTap;

  /// background color for canvas
  @override
  Color backgroundColor() {
    return flameBackgroundColor ?? mat.Colors.white;
  }

  @override
  Future<void> onLoad() async {
    /// 首先加画布组件
    world.add(CanvasComponent());

    /// 加中心聚焦组件
    world.add(focusPoint = FocusPointImpl());

    /// 设置画布的边界使得摄像头不可以超出范围
    camera.setBounds(Rectangle.fromPoints(
        Vector2(0, 0), Vector2(CanvasComponent.size, CanvasComponent.size)));

    ///  摄像头跟随画布中心移动
    camera.follow(
      focusPoint,
    );

    /// 渲染画布上的所有节点和线
    void renderData() {
      double i = 0;
      double j = 0;

      /// render the nodes in the screen
      List<Node> nodes = modelCanvasController.nodes.values.toList();
      for (Node node in nodes) {
        double nodei = i;
        double nodej = j;
        NodePositionComponent nodePositionComponent = NodePositionComponent(
          nodeSize: Vector2(
              (nodeSize + (nodePadding * 2)), (nodeSize + (nodePadding * 2))),
          nodePosition: Vector2(nodej, nodei),
          nodePadding: nodePadding,
          node: node,
          nodeImageSize: nodeSize,
        );
        world.add(nodePositionComponent);
        modelCanvasController.nodePositionComponents[node.name] =
            nodePositionComponent;

        if (j < CanvasComponent.size - (nodeSize + (nodePadding * 2))) {
          j = j + (nodeSize + (nodePadding * 2));
        } else {
          i = i + (nodeSize + (nodePadding * 2));
          j = 0;
        }
      }
    }

    /// 渲染线
    void addLines() {
      List<Node> nodes = modelCanvasController.nodes.values.toList();
      for (Node node in nodes) {
        LineDrawer lineDrawer = LineDrawer(
            node: node, modelCanvasController: modelCanvasController);
        world.add(lineDrawer);
      }
    }

    /// render the nodes in the screen
    renderData();

    /// once node is rendered then render the lines
    addLines();
  }

  static const speed = 2000.0;

  @override
  void update(double dt) {
    super.update(dt);

    /// update the zoom value based on the controllers input
    camera.viewfinder.zoom = modelCanvasController.zoom ?? 1;
  }
}
