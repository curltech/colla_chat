import 'package:colla_chat/pages/game/model/flame/model_canvas_controller.dart';
import 'package:colla_chat/pages/game/model/flame/model_canvas_widget.dart';
import 'package:colla_chat/pages/game/model/flame/node.dart';
import 'package:colla_chat/pages/game/model/flame/node_position_component.dart';
import 'package:colla_chat/pages/game/model/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/meta_model_node.dart';
import 'package:colla_chat/pages/game/model/meta_model_node_widget.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 画布
class MetaCanvasWidget extends StatelessWidget {
  final GlobalKey _key = GlobalKey();

  MetaCanvasWidget({super.key});

  Widget _buildModelCanvasWidget() {
    ModelCanvasController? modelCanvasController =
        modelProjectController.getModelCanvasController();
    if (modelCanvasController == null) {
      modelCanvasController = ModelCanvasController();
      String? packageName = modelProjectController.currentPackageName.value;
      modelProjectController.packageModelCanvasController[packageName!] =
          modelCanvasController;
    }
    return ModelCanvasWidget<MetaModelNode>(
      nodePadding: 50,
      nodeSize: 200,
      isDebug: false,
      backgroundColor: Colors.black,
      modelCanvasController: modelCanvasController,
      onDrawLine: (lineFrom, lineTwo) {
        return Paint()
          ..color = Colors.blue
          ..strokeWidth = 1.5;
      },
      builder: (node) {
        return SizedBox(
          width: 100,
          height: 100,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                (node).name,
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTapDown: (TapDownDetails details) {
          if (modelProjectController.addElementStatus.value) {
            MetaModelNode metaModelNode = MetaModelNode(
                name: 'unknown',
                modelProjectController.currentPackageName.value!);
            ModelCanvasController? modelCanvasController =
                modelProjectController.getModelCanvasController();
            if (modelCanvasController != null) {
              modelCanvasController.nodes[metaModelNode.name] = metaModelNode;
            }

            modelProjectController.addElementStatus.value = false;
          }
        },
        child: _buildModelCanvasWidget());
  }
}

/// 画关系线的画笔
/// CustomPaint的child指定绘制区域，而且RepaintBoundary(child:...)
class RelationshipLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    ModelCanvasController? modelCanvasController =
        modelProjectController.getModelCanvasController();
    if (modelCanvasController == null) {
      return;
    }
    for (var entry in modelCanvasController.nodeRelationships.entries) {
      List<NodeRelationship> ships = entry.value;
      Node node = entry.key;
      for (NodeRelationship ship in ships) {
        if (!modelCanvasController.nodePositionComponents
            .containsKey(node.name)) {
          break;
        }
        NodePositionComponent nodePositionComponent =
            modelCanvasController.nodePositionComponents[node.name]!;
        NodePositionComponent dstNodePositionComponent =
            modelCanvasController.nodePositionComponents[ship.dst.name]!;
        Offset? srcOffset =
            dstNodePositionComponent.spriteComponent.center.toOffset();
        Offset? dstOffset =
            nodePositionComponent.spriteComponent.center.toOffset();
        Path path = Path();
        double sdx = srcOffset.dx + elementWidth / 2;
        double sdy = srcOffset.dy;
        double ddx = dstOffset.dx + elementWidth / 2;
        double ddy = dstOffset.dy + elementHeight;
        path.moveTo(sdx, sdy);
        path.lineTo(sdx, (sdy - ddy) / 2 + ddy);
        path.lineTo((ddx - sdx) + sdx, (sdy - ddy) / 2 + ddy);
        path.lineTo((ddx - sdx) + sdx, ddy);
        var paint = Paint()..color = Colors.blueAccent; //2080E5
        paint.strokeWidth = 1.0;
        paint.style = PaintingStyle.stroke;
        canvas.drawPath(path, paint);
      }
    }
  }

  // 返回false, 后面介绍
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
