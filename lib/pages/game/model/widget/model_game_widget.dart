import 'dart:math';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// [ModelGameWidget] flutter的画布组件，内含ModelCanvasFlame的实现组件
class ModelGameWidget<T extends Node> extends StatefulWidget {
  const ModelGameWidget({
    super.key,
  });

  @override
  State<ModelGameWidget> createState() => _ModelGameWidgetState();
}

class _ModelGameWidgetState extends State<ModelGameWidget> {
  late int length;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ModelFlameGame modelFlameGame = ModelFlameGame();
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
