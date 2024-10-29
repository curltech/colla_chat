import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// [LineComponent] 在src节点和dst关系节点之间画关系的连线
class LineComponent extends PositionComponent with HasGameRef<ModelFlameGame> {
  static final strokePaint = BasicPalette.blue.paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  LineComponent({required this.nodeRelationship}) : super();

  /// [Node] draws line to its relationship nodes，this node is src node
  final NodeRelationship nodeRelationship;

  Paint defaultPaint(lineFrom, lineTo) {
    return Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5;
  }

  @override
  Future<void> onLoad() async {}

  @override
  void render(Canvas canvas) {
    double srcX = nodeRelationship.src!.nodePositionComponent!.position.x;
    double srcY = nodeRelationship.src!.nodePositionComponent!.position.y;
    double srcHeight = nodeRelationship.src!.nodePositionComponent!.size.y;
    Vector2 srcTopCenter = Vector2(srcX + Project.nodeWidth / 2, srcY);
    Vector2 srcLeftCenter = Vector2(srcX, srcY + srcHeight / 2);
    Vector2 srcRightCenter =
        Vector2(srcX + Project.nodeWidth, srcY + srcHeight / 2);
    Vector2 srcBottomCenter =
        Vector2(srcX + Project.nodeWidth / 2, srcY + srcHeight);

    double dstX = nodeRelationship.dst!.nodePositionComponent!.position.x;
    double dstY = nodeRelationship.dst!.nodePositionComponent!.position.y;
    double dstHeight = nodeRelationship.dst!.nodePositionComponent!.size.y;
    Vector2 dstTopCenter = Vector2(dstX + Project.nodeWidth / 2, dstY);
    Vector2 dstLeftCenter = Vector2(dstX, dstY + srcHeight / 2);
    Vector2 dstRightCenter =
        Vector2(dstX + Project.nodeWidth, dstY + srcHeight / 2);
    Vector2 dstBottomCenter =
        Vector2(dstX + Project.nodeWidth / 2, dstY + srcHeight);
    Offset from;
    Offset to;
    Path path = Path();
    if (srcX + Project.nodeWidth < dstX) {
      // src在dst的左边
      if (srcY < dstY) {
        // src在dst的上边
        if (srcY + srcHeight / 2 < dstY) {
          // src在dst的全上边
          from = Offset(srcRightCenter.x, srcRightCenter.y);
          to = Offset(dstTopCenter.x, dstTopCenter.y);
          path.moveTo(srcRightCenter.x, srcRightCenter.y);
          path.lineTo(dstTopCenter.x, srcRightCenter.y);
          path.lineTo(dstTopCenter.x, dstTopCenter.y);
        } else {
          from = Offset(srcRightCenter.x, srcRightCenter.y);
          to = Offset(dstLeftCenter.x, dstLeftCenter.y);
          path.moveTo(srcRightCenter.x, srcRightCenter.y);
          path.lineTo(
              srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
              srcRightCenter.y);
          path.lineTo(
              srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
              dstLeftCenter.y);
          path.lineTo(dstLeftCenter.x, dstLeftCenter.y);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY) {
          // src在dst的全下边
          from = Offset(srcTopCenter.x, srcTopCenter.y);
          to = Offset(dstBottomCenter.x, dstBottomCenter.y);
          path.moveTo(srcTopCenter.x, srcTopCenter.y);
          path.lineTo(srcTopCenter.x,
              srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2);
          path.lineTo(dstBottomCenter.x,
              srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2);
          path.lineTo(dstBottomCenter.x, dstBottomCenter.y);
        } else {
          from = Offset(srcRightCenter.x, srcRightCenter.y);
          to = Offset(dstLeftCenter.x, dstLeftCenter.y);
          path.moveTo(srcRightCenter.x, srcRightCenter.y);
          path.lineTo(
              srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
              srcRightCenter.y);
          path.lineTo(
              srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
              dstLeftCenter.y);
          path.lineTo(dstLeftCenter.x, dstLeftCenter.y);
        }
      }
    } else if (dstX + Project.nodeWidth < srcX) {
      // src在dst的右边
      if (srcY < dstY) {
        // src在dst的上边
        if (srcY + srcHeight < dstY) {
          // src在dst的全上边
          from = Offset(srcLeftCenter.x, srcLeftCenter.y);
          to = Offset(dstTopCenter.x, dstTopCenter.y);
        } else {
          from = Offset(srcLeftCenter.x, srcLeftCenter.y);
          to = Offset(dstRightCenter.x, dstRightCenter.y);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY) {
          // src在dst的全下边
          from = Offset(srcTopCenter.x, srcTopCenter.y);
          to = Offset(dstBottomCenter.x, dstBottomCenter.y);
        } else {
          from = Offset(srcLeftCenter.x, srcLeftCenter.y);
          to = Offset(dstRightCenter.x, dstRightCenter.y);
        }
      }
    } else {
      // src和dst同边
      if (srcY < dstY) {
        // src在dst的上边
        if (srcY + srcHeight < dstY) {
          // src在dst的全上边
          from = Offset(srcBottomCenter.x, srcBottomCenter.y);
          to = Offset(dstTopCenter.x, dstTopCenter.y);
        } else {
          from = Offset(srcLeftCenter.x, srcLeftCenter.y);
          to = Offset(dstTopCenter.x, dstTopCenter.y);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY) {
          // src在dst的全下边
          from = Offset(srcTopCenter.x, srcTopCenter.y);
          to = Offset(dstBottomCenter.x, dstBottomCenter.y);
        } else {
          from = Offset(srcLeftCenter.x, srcLeftCenter.y);
          to = Offset(dstBottomCenter.x, dstBottomCenter.y);
        }
      }
    }
    canvas.drawPath(path, strokePaint);
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
    var paint = Paint()..color = Colors.blueAccent;
    paint.strokeWidth = 1.0;
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  // 返回false, 后面介绍
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
