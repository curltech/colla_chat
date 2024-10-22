import 'dart:math';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/controller/model_world_controller.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// [ModelGameWidget] flutter的画布组件，内含ModelCanvasFlame的实现组件
class ModelGameWidget<T extends Node> extends StatefulWidget {
  /// [nodeSize] represents the size of the node

  // final GraphNode head;
  final double nodeSize;

  /// [nodeSize] represents padding between the nodes
  final double nodePadding;

  /// [isDebug] will show the wireframe
  final bool isDebug;

  /// [isDebug] decide the paint needed to draw the line
  final Paint? Function(T lineFrom, T lineTwo)? onDrawLine;

  /// [builder] 构造器构造节点的flutter组件
  final Widget Function(T node) builder;

  /// [advancedGraphviewController] will give you the control to handle state
  final ModelWorldController modelWorldController;

  /// set the background color of the canvas
  final Color? backgroundColor;

  /// pixel ratio sets the widget pixel ratio
  final double pixelRatio;

  /// action when you tap a node
  final Function(Node)? onNodeTap;

  /// [ModelGameWidget] will create tree structured nodes
  const ModelGameWidget({
    super.key,
    required this.nodePadding,
    required this.nodeSize,
    required this.builder,
    this.isDebug = false,
    required this.modelWorldController,
    this.onDrawLine,
    this.backgroundColor,
    this.pixelRatio = 1,
    this.onNodeTap,
  });

  static late BuildContext context;

  @override
  State<ModelGameWidget> createState() => _ModelGameWidgetState();
}

class _ModelGameWidgetState extends State<ModelGameWidget> {
  bool loader = true;
  late int length;

  @override
  void initState() {
    super.initState();
    ModelGameWidget.context = context;
  }

  /// The image will start loading once loaded it starts caching the data
  double getAreaSize() {
    Set<String> items = widget.modelWorldController.nodes.keys.toSet();
    length = sqrt(items.length).ceil();
    double size = (widget.nodeSize + (widget.nodePadding * 2)) * length;
    widget.modelWorldController.maxScrollExtent = size;

    return size;
  }

  @override
  Widget build(BuildContext context) {
    if (loader) return const SizedBox();
    ModelFlameGame modelFlameGame = ModelFlameGame(
      nodePadding: widget.nodePadding,
      nodeSize: widget.nodeSize,
      context: context,
      isDebug: widget.isDebug,
      onDrawLine: widget.onDrawLine,
      flameBackgroundColor: widget.backgroundColor,
      modelWorldController: widget.modelWorldController,
      pixelRatio: widget.pixelRatio,
      onNodeTap: widget.onNodeTap,
    );
    return GameWidget(
      game: modelFlameGame,
    );
  }
}

/// 画关系线的画笔
/// CustomPaint的child指定绘制区域，而且RepaintBoundary(child:...)
class RelationshipLinePainter extends CustomPainter {
  final NodeRelationship nodeRelationship;

  RelationshipLinePainter(this.nodeRelationship);

  @override
  void paint(Canvas canvas, Size size) {
    Offset? srcOffset =
    nodeRelationship.src?.nodePositionComponent?.center.toOffset();
    Offset? dstOffset =
    nodeRelationship.dst?.nodePositionComponent?.center.toOffset();
    if (srcOffset == null || dstOffset == null) {
      return;
    }
    Path path = Path();
    double sdx = srcOffset.dx + 200 / 2;
    double sdy = srcOffset.dy;
    double ddx = dstOffset.dx + 200 / 2;
    double ddy = dstOffset.dy + 200;
    path.moveTo(sdx, sdy);
    path.lineTo(sdx, (sdy - ddy) / 2 + ddy);
    path.lineTo((ddx - sdx) + sdx, (sdy - ddy) / 2 + ddy);
    path.lineTo((ddx - sdx) + sdx, ddy);
    var paint = Paint()..color = Colors.blueAccent; //2080E5
    paint.strokeWidth = 1.0;
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  // 返回false, 后面介绍
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
