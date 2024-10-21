import 'dart:math';

import 'package:colla_chat/pages/game/model/flame/canvas_component.dart';
import 'package:colla_chat/pages/game/model/flame/model_canvas_controller.dart';
import 'package:colla_chat/pages/game/model/flame/model_canvas_flame.dart';
import 'package:colla_chat/pages/game/model/flame/node.dart';
import 'package:colla_chat/pages/game/model/flame/node_renderer_widget.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// [ModelCanvasWidget] flutter的画布组件，内含ModelCanvasFlame的实现组件
class ModelCanvasWidget<T extends Node> extends StatefulWidget {
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
  final ModelCanvasController modelCanvasController;

  /// set the background color of the canvas
  final Color? backgroundColor;

  /// pixel ratio sets the widget pixel ratio
  final double pixelRatio;

  /// action when you tap a node
  final Function(Node)? onNodeTap;

  /// [ModelCanvasWidget] will create tree structured nodes
  const ModelCanvasWidget({
    super.key,
    required this.nodePadding,
    required this.nodeSize,
    required this.builder,
    this.isDebug = false,
    required this.modelCanvasController,
    this.onDrawLine,
    this.backgroundColor,
    this.pixelRatio = 1,
    this.onNodeTap,
  });

  static late BuildContext context;

  @override
  State<ModelCanvasWidget> createState() => _ModelCanvasWidgetState();
}

class _ModelCanvasWidgetState extends State<ModelCanvasWidget> {
  bool loader = true;
  late int length;
  late Map<String, Node> nodeMap;

  @override
  void initState() {
    super.initState();
    ModelCanvasWidget.context = context;
    startLoadingImage();
  }

  /// The image will start loading once loaded it starts caching the data
  void startLoadingImage() async {
    await loadImage();

    Set<String> items = widget.modelCanvasController.nodes.keys.toSet();
    length = sqrt(items.length).ceil();
    CanvasComponent.size =
        (widget.nodeSize + (widget.nodePadding * 2)) * length;
    nodeMap = widget.modelCanvasController.nodes;
    widget.modelCanvasController.maxScrollExtent = CanvasComponent.size;
    setState(() {
      loader = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loader) return const SizedBox();
    return Stack(
      children: [
        ...widget.modelCanvasController.nodes.values.map(
          (e) => NodeRendererWidget(
            modelCanvasController: widget.modelCanvasController,
            nodeSize: Vector2(widget.nodeSize, widget.nodeSize),
            pixelRatio: widget.pixelRatio,
            node: e,
            child: widget.builder(e),
          ),
        ),
        GameWidget(
          game: ModelCanvasFlame(
            nodePadding: widget.nodePadding,
            nodeSize: widget.nodeSize,
            context: context,
            isDebug: widget.isDebug,
            onDrawLine: widget.onDrawLine,
            flameBackgroundColor: widget.backgroundColor,
            modelCanvasController: widget.modelCanvasController,
            pixelRatio: widget.pixelRatio,
            onNodeTap: widget.onNodeTap,
          ),
        ),

        //const PickerScreen(pickerScreenDataFirst: ,)
      ],
    );
  }
}
