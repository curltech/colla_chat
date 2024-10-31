import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/relationship_edit_widget.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// [LineComponent] 在src节点和dst关系节点之间画关系的连线
class LineComponent extends PositionComponent
    with TapCallbacks, DoubleTapCallbacks, HasGameRef<ModelFlameGame> {
  static final strokePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  LineComponent({required this.nodeRelationship}) : super() {
    Node? src = nodeRelationship.src;
    if (src == null && nodeRelationship.srcName != null) {
      ModelNode? srcNode =
          modelProjectController.getModelNode(nodeRelationship.srcName!);
      nodeRelationship.src = srcNode;
    }
    Node? dst = nodeRelationship.dst;
    if (dst == null && nodeRelationship.dstName != null) {
      ModelNode? dstNode =
          modelProjectController.getModelNode(nodeRelationship.dstName!);
      nodeRelationship.dst = dstNode;
    }
  }

  /// [Node] draws line to its relationship nodes，this node is src node
  final NodeRelationship nodeRelationship;

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
    if (nodeRelationship.src!.nodePositionComponent!.modelNode ==
        nodeRelationship.dst!.nodePositionComponent!.modelNode) {
      from = Offset(srcBottomCenter.x, srcBottomCenter.y);
      to = Offset(dstRightCenter.x, dstRightCenter.y);
      path.moveTo(srcBottomCenter.x, srcBottomCenter.y);
      path.lineTo(srcBottomCenter.x, srcBottomCenter.y + 30);
      path.lineTo(
          srcBottomCenter.x + Project.nodeWidth, srcBottomCenter.y + 30);
      path.lineTo(srcBottomCenter.x + Project.nodeWidth, dstRightCenter.y);
      path.lineTo(dstRightCenter.x, dstRightCenter.y);

      path.lineTo(dstRightCenter.x + 12, dstRightCenter.y - 4);
      path.moveTo(dstRightCenter.x, dstRightCenter.y);
      path.lineTo(dstRightCenter.x + 12, dstRightCenter.y + 4);
      canvas.drawPath(path, strokePaint);

      return;
    }
    if (srcX + Project.nodeWidth < dstX) {
      // src在dst的左边
      if (srcY < dstY) {
        // src在dst的上边
        if (srcY + srcHeight < dstY - 30) {
          // src在dst的全上边
          from = Offset(srcBottomCenter.x, srcBottomCenter.y);
          to = Offset(dstTopCenter.x, dstTopCenter.y);
          path.moveTo(srcBottomCenter.x, srcBottomCenter.y);
          path.lineTo(srcBottomCenter.x,
              srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
          path.lineTo(dstTopCenter.x,
              srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
          path.lineTo(dstTopCenter.x, dstTopCenter.y);

          path.lineTo(dstTopCenter.x - 4, dstTopCenter.y - 12);
          path.moveTo(dstTopCenter.x, dstTopCenter.y);
          path.lineTo(dstTopCenter.x + 4, dstTopCenter.y - 12);
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

          path.lineTo(dstLeftCenter.x - 12, dstLeftCenter.y - 4);
          path.moveTo(dstLeftCenter.x, dstLeftCenter.y);
          path.lineTo(dstLeftCenter.x - 12, dstLeftCenter.y + 4);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY - 30) {
          // src在dst的全下边
          from = Offset(srcTopCenter.x, srcTopCenter.y);
          to = Offset(dstBottomCenter.x, dstBottomCenter.y);
          path.moveTo(srcTopCenter.x, srcTopCenter.y);
          path.lineTo(srcTopCenter.x,
              srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2);
          path.lineTo(dstBottomCenter.x,
              srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2);
          path.lineTo(dstBottomCenter.x, dstBottomCenter.y);

          path.lineTo(dstBottomCenter.x - 4, dstBottomCenter.y + 12);
          path.moveTo(dstBottomCenter.x, dstBottomCenter.y);
          path.lineTo(dstBottomCenter.x + 4, dstBottomCenter.y + 12);
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

          path.lineTo(dstLeftCenter.x - 12, dstLeftCenter.y - 4);
          path.moveTo(dstLeftCenter.x, dstLeftCenter.y);
          path.lineTo(dstLeftCenter.x - 12, dstLeftCenter.y + 4);
        }
      }
    } else if (dstX + Project.nodeWidth < srcX) {
      // src在dst的右边
      if (srcY < dstY) {
        // src在dst的上边
        if (srcY + srcHeight < dstY - 30) {
          // src在dst的全上边
          from = Offset(srcBottomCenter.x, srcBottomCenter.y);
          to = Offset(dstTopCenter.x, dstTopCenter.y);
          path.moveTo(srcBottomCenter.x, srcBottomCenter.y);
          path.lineTo(srcBottomCenter.x,
              srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
          path.lineTo(dstTopCenter.x,
              srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
          path.lineTo(dstTopCenter.x, dstTopCenter.y);

          path.lineTo(dstTopCenter.x - 4, dstTopCenter.y - 12);
          path.moveTo(dstTopCenter.x, dstTopCenter.y);
          path.lineTo(dstTopCenter.x + 4, dstTopCenter.y - 12);
        } else {
          from = Offset(srcLeftCenter.x, srcLeftCenter.y);
          to = Offset(dstRightCenter.x, dstRightCenter.y);
          path.moveTo(srcLeftCenter.x, srcLeftCenter.y);
          path.lineTo(
              srcLeftCenter.x - (srcLeftCenter.x - dstRightCenter.x) / 2,
              srcLeftCenter.y);
          path.lineTo(
              srcLeftCenter.x - (srcLeftCenter.x - dstRightCenter.x) / 2,
              dstRightCenter.y);
          path.lineTo(dstRightCenter.x, dstRightCenter.y);

          path.lineTo(dstRightCenter.x + 12, dstRightCenter.y - 4);
          path.moveTo(dstRightCenter.x, dstRightCenter.y);
          path.lineTo(dstRightCenter.x + 12, dstRightCenter.y + 4);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY - 30) {
          // src在dst的全下边
          from = Offset(srcTopCenter.x, srcTopCenter.y);
          to = Offset(dstBottomCenter.x, dstBottomCenter.y);
          path.moveTo(srcTopCenter.x, srcTopCenter.y);
          path.lineTo(srcTopCenter.x,
              srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2);
          path.lineTo(dstBottomCenter.x,
              srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2);
          path.lineTo(dstBottomCenter.x, dstBottomCenter.y);

          path.lineTo(dstBottomCenter.x - 4, dstBottomCenter.y + 12);
          path.moveTo(dstBottomCenter.x, dstBottomCenter.y);
          path.lineTo(dstBottomCenter.x + 4, dstBottomCenter.y + 12);
        } else {
          from = Offset(srcLeftCenter.x, srcLeftCenter.y);
          to = Offset(dstRightCenter.x, dstRightCenter.y);
          path.moveTo(srcLeftCenter.x, srcLeftCenter.y);
          path.lineTo(
              srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
              srcRightCenter.y);
          path.lineTo(
              srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
              dstLeftCenter.y);
          path.lineTo(dstRightCenter.x, dstRightCenter.y);

          path.lineTo(dstRightCenter.x + 12, dstRightCenter.y - 4);
          path.moveTo(dstRightCenter.x, dstRightCenter.y);
          path.lineTo(dstRightCenter.x + 12, dstRightCenter.y + 4);
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
          path.moveTo(srcBottomCenter.x, srcBottomCenter.y);
          path.lineTo(srcBottomCenter.x,
              srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
          path.lineTo(dstTopCenter.x,
              srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
          path.lineTo(dstTopCenter.x, dstTopCenter.y);

          path.lineTo(dstTopCenter.x - 4, dstTopCenter.y - 12);
          path.moveTo(dstTopCenter.x, dstTopCenter.y);
          path.lineTo(dstTopCenter.x + 4, dstTopCenter.y - 12);
        } else {
          from = Offset(srcBottomCenter.x, srcBottomCenter.y);
          to = Offset(dstTopCenter.x, dstTopCenter.y);
          path.moveTo(srcBottomCenter.x, srcBottomCenter.y);
          path.lineTo(srcBottomCenter.x,
              srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
          path.lineTo(dstTopCenter.x,
              srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
          path.lineTo(dstTopCenter.x, dstTopCenter.y);

          path.lineTo(dstTopCenter.x - 4, dstTopCenter.y - 12);
          path.moveTo(dstTopCenter.x, dstTopCenter.y);
          path.lineTo(dstTopCenter.x + 4, dstTopCenter.y - 12);
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

          path.lineTo(dstBottomCenter.x - 4, dstBottomCenter.y + 12);
          path.moveTo(dstBottomCenter.x, dstBottomCenter.y);
          path.lineTo(dstBottomCenter.x + 4, dstBottomCenter.y + 12);
        } else {
          from = Offset(srcLeftCenter.x, srcLeftCenter.y);
          to = Offset(dstBottomCenter.x, dstBottomCenter.y);
          path.moveTo(srcLeftCenter.x, srcLeftCenter.y);
          path.lineTo(dstBottomCenter.x, srcLeftCenter.y);
          path.lineTo(dstBottomCenter.x, dstBottomCenter.y);

          path.lineTo(dstTopCenter.x - 4, dstTopCenter.y - 12);
          path.moveTo(dstTopCenter.x, dstTopCenter.y);
          path.lineTo(dstTopCenter.x + 4, dstTopCenter.y - 12);
        }
      }
    }
    canvas.drawPath(path, strokePaint);
  }

  @override
  Future<void> onDoubleTapDown(DoubleTapDownEvent event) async {
    await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return RelationshipEditWidget(
        nodeRelationship: nodeRelationship,
      );
    });
  }
}
