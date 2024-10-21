import 'package:colla_chat/pages/game/model/flame/node.dart';
import 'package:colla_chat/pages/game/model/flame/node_position_component.dart';
import 'package:flutter/material.dart';

/// [ModelCanvasController] 控制画布和画布上所有节点的状态
class ModelCanvasController extends ValueNotifier {
  /// 节点name和节点捕获图像之间的映射
  final Map<String, Node> nodes = {};

  final Map<String, NodePositionComponent> nodePositionComponents = {};

  /// src节点和关系节点列表之间的映射
  final Map<Node, List<NodeRelationship>> nodeRelationships = {};

  /// [ModelCanvasController] will control the state of the widget
  ModelCanvasController() : super(null);

  /// [scrollX] give it to control the scroll in canvas
  double? scrollX;

  /// [scrollY] give it to control the scroll in canvas
  double? scrollY;

  /// [maxScrollExtent] max scroll extent in canvas
  double? maxScrollExtent;

  /// [zoom] zoom level in canvas
  double? zoom;

  /// [setScroll] will scroll the in canvas
  void setScroll({double? scrollX, double? scrollY}) {
    this.scrollX = scrollX;
    this.scrollY = scrollY;
  }

  /// [setZoomValue]  zoom level in canvas
  void setZoomValue({double? zoom}) {
    this.zoom = zoom;
  }

  /// [clear] clear the nodes
  void clear() {
    nodes.clear();
    nodePositionComponents.clear();
    nodeRelationships.clear();
  }
}
