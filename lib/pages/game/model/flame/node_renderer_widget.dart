import 'dart:ui' as ui;

import 'package:colla_chat/pages/game/model/flame/model_canvas_controller.dart';
import 'package:colla_chat/pages/game/model/flame/node.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// this stores the transparent image
late ui.Image transparentImage;

/// loads the transparent image
Future<void> loadImage() async {
  /// The base 64 string here is 1x1 pixel transparent image
  transparentImage = await Flame.images.fromBase64('key',
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=");
}

/// [NodeRendererWidget] flutter的节点组件，内含child，是node构造器构造
class NodeRendererWidget extends StatefulWidget {
  /// [child] is the child to be rendered in the tree lead
  final Widget child;

  /// [nodeSize] size of the widget
  final Vector2 nodeSize;

  /// [node] graphnode will point to the tree
  final ModelCanvasController modelCanvasController;

  final Node node;

  /// [pixelRatio] defines resolution of the widget
  final double pixelRatio;

  const NodeRendererWidget({
    super.key,
    required this.child,
    required this.nodeSize,
    required this.modelCanvasController,
    required this.node,
    required this.pixelRatio,
  });

  @override
  State<NodeRendererWidget> createState() => _NodeRendererWidgetState();
}

class _NodeRendererWidgetState extends State<NodeRendererWidget> {
  GlobalKey globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(
        const Duration(seconds: 1),
        () => _capturePng(),
      );
    });
  }

  Future<void> _capturePng() async {
    RenderRepaintBoundary boundary =
        globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: widget.pixelRatio);
    widget.node.image = image;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.nodeSize.x,
        height: widget.nodeSize.y,
        child: RepaintBoundary(
          key: globalKey,
          child: Align(
            child: SizedBox(
              width: widget.nodeSize.x,
              height: widget.nodeSize.y,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
