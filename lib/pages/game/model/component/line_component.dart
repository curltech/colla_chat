import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_position_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/relationship_edit_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
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
    if (src == null) {
      ModelNode? srcNode =
          modelProjectController.getModelNode(nodeRelationship.srcId);
      if (srcNode != null) {
        nodeRelationship.src = srcNode;
      } else {
        logger
            .e('nodeRelationship srcId:${nodeRelationship.srcId} has no node');
      }
    }
    Node? dst = nodeRelationship.dst;
    if (dst == null) {
      ModelNode? dstNode =
          modelProjectController.getModelNode(nodeRelationship.dstId);
      if (dstNode != null) {
        nodeRelationship.dst = dstNode;
      } else {
        logger
            .e('nodeRelationship dstId:${nodeRelationship.dstId} has no node');
      }
    }
  }

  /// [Node] draws line to its relationship nodes，this node is src node
  final NodeRelationship nodeRelationship;

  @override
  Future<void> onLoad() async {}

  @override
  void render(Canvas canvas) {
    if (nodeRelationship.src == null) {
      return;
    }
    NodePositionComponent? srcNodePositionComponent =
        nodeRelationship.src!.nodePositionComponent;
    if (srcNodePositionComponent == null) {
      return;
    }
    double srcX = srcNodePositionComponent.position.x;
    double srcY = srcNodePositionComponent.position.y;
    double srcHeight = srcNodePositionComponent.size.y;
    Vector2 srcTopCenter = Vector2(srcX + Project.nodeWidth / 2, srcY);
    Vector2 srcLeftCenter = Vector2(srcX, srcY + srcHeight / 2);
    Vector2 srcRightCenter =
        Vector2(srcX + Project.nodeWidth, srcY + srcHeight / 2);
    Vector2 srcBottomCenter =
        Vector2(srcX + Project.nodeWidth / 2, srcY + srcHeight);

    if (nodeRelationship.dst == null) {
      return;
    }
    NodePositionComponent? dstNodePositionComponent =
        nodeRelationship.dst!.nodePositionComponent;
    if (dstNodePositionComponent == null) {
      return;
    }
    double dstX = dstNodePositionComponent.position.x;
    double dstY = dstNodePositionComponent.position.y;
    double dstHeight = dstNodePositionComponent.size.y;
    Vector2 dstTopCenter = Vector2(dstX + Project.nodeWidth / 2, dstY);
    Vector2 dstLeftCenter = Vector2(dstX, dstY + srcHeight / 2);
    Vector2 dstRightCenter =
        Vector2(dstX + Project.nodeWidth, dstY + srcHeight / 2);
    Vector2 dstBottomCenter =
        Vector2(dstX + Project.nodeWidth / 2, dstY + srcHeight);

    Path path = Path();
    if (srcNodePositionComponent.modelNode ==
        dstNodePositionComponent.modelNode) {
      selfLine(path, srcBottomCenter, srcRightCenter);
      rightCenterArrow(path, srcRightCenter);
      canvas.drawPath(path, strokePaint);

      return;
    }
    if (srcX + Project.nodeWidth < dstX) {
      // src在dst的左边
      if (srcY < dstY) {
        // src在dst的上边
        if (srcY + srcHeight < dstY - 30) {
          // src在dst的全上边
          bottomTopLine(path, srcBottomCenter, dstTopCenter);
          topCenterArrow(path, dstTopCenter);
        } else {
          rightLeftLine(path, srcRightCenter, dstLeftCenter);
          leftCenterArrow(path, dstLeftCenter);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY - 30) {
          // src在dst的全下边
          topBottomLine(path, srcTopCenter, dstBottomCenter);
          bottomCenterArrow(path, dstBottomCenter);
        } else {
          rightLeftLine(path, srcRightCenter, dstLeftCenter);
          leftCenterArrow(path, dstLeftCenter);
        }
      }
    } else if (dstX + Project.nodeWidth < srcX) {
      // src在dst的右边
      if (srcY < dstY) {
        // src在dst的上边
        if (srcY + srcHeight < dstY - 30) {
          // src在dst的全上边
          bottomTopLine(path, srcBottomCenter, dstTopCenter);
          topCenterArrow(path, dstTopCenter);
        } else {
          leftRightLine(path, srcLeftCenter, dstRightCenter);
          rightCenterArrow(path, dstRightCenter);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY - 30) {
          // src在dst的全下边
          topBottomLine(path, srcTopCenter, dstBottomCenter);
          bottomCenterArrow(path, dstBottomCenter);
        } else {
          leftRightLine(path, srcLeftCenter, dstRightCenter);
          rightCenterArrow(path, dstRightCenter);
        }
      }
    } else {
      // src和dst同边
      if (srcY < dstY) {
        // src在dst的上边
        if (srcY + srcHeight < dstY) {
          // src在dst的全上边
          bottomTopLine(path, srcBottomCenter, dstTopCenter);
          topCenterArrow(path, dstTopCenter);
        } else {
          bottomTopLine(path, srcBottomCenter, dstTopCenter);
          topCenterArrow(path, dstTopCenter);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY) {
          // src在dst的全下边
          topBottomLine(path, srcTopCenter, dstBottomCenter);
          bottomCenterArrow(path, dstBottomCenter);
        } else {
          leftBottomLine(path, srcLeftCenter, dstBottomCenter);
          topCenterArrow(path, dstTopCenter);
        }
      }
    }
    canvas.drawPath(path, strokePaint);
  }

  void leftBottomLine(
      Path path, Vector2 srcLeftCenter, Vector2 dstBottomCenter) {
    path.moveTo(srcLeftCenter.x, srcLeftCenter.y);
    path.lineTo(dstBottomCenter.x, srcLeftCenter.y);
    path.lineTo(dstBottomCenter.x, dstBottomCenter.y);
  }

  void leftRightLine(Path path, Vector2 srcLeftCenter, Vector2 dstRightCenter) {
    path.moveTo(srcLeftCenter.x, srcLeftCenter.y);
    path.lineTo(srcLeftCenter.x - (srcLeftCenter.x - dstRightCenter.x) / 2,
        srcLeftCenter.y);
    path.lineTo(srcLeftCenter.x - (srcLeftCenter.x - dstRightCenter.x) / 2,
        dstRightCenter.y);
    path.lineTo(dstRightCenter.x, dstRightCenter.y);
  }

  void topBottomLine(Path path, Vector2 srcTopCenter, Vector2 dstBottomCenter) {
    path.moveTo(srcTopCenter.x, srcTopCenter.y);
    path.lineTo(srcTopCenter.x,
        srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2);
    path.lineTo(dstBottomCenter.x,
        srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2);
    path.lineTo(dstBottomCenter.x, dstBottomCenter.y);
  }

  void rightLeftLine(Path path, Vector2 srcRightCenter, Vector2 dstLeftCenter) {
    path.moveTo(srcRightCenter.x, srcRightCenter.y);
    path.lineTo(srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
        srcRightCenter.y);
    path.lineTo(srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
        dstLeftCenter.y);
    path.lineTo(dstLeftCenter.x, dstLeftCenter.y);
  }

  void bottomTopLine(Path path, Vector2 srcBottomCenter, Vector2 dstTopCenter) {
    path.moveTo(srcBottomCenter.x, srcBottomCenter.y);
    path.lineTo(srcBottomCenter.x,
        srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
    path.lineTo(dstTopCenter.x,
        srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
    path.lineTo(dstTopCenter.x, dstTopCenter.y);
  }

  void selfLine(Path path, Vector2 srcBottomCenter, Vector2 srcRightCenter) {
    path.moveTo(srcBottomCenter.x, srcBottomCenter.y);
    path.lineTo(srcBottomCenter.x, srcBottomCenter.y + 30);
    path.lineTo(srcBottomCenter.x + Project.nodeWidth, srcBottomCenter.y + 30);
    path.lineTo(srcBottomCenter.x + Project.nodeWidth, srcRightCenter.y);
    path.lineTo(srcRightCenter.x, srcRightCenter.y);
  }

  void bottomCenterArrow(Path path, Vector2 dstBottomCenter) {
    path.lineTo(dstBottomCenter.x - 4, dstBottomCenter.y + 12);
    path.moveTo(dstBottomCenter.x, dstBottomCenter.y);
    path.lineTo(dstBottomCenter.x + 4, dstBottomCenter.y + 12);
  }

  void leftCenterArrow(Path path, Vector2 dstLeftCenter) {
    path.lineTo(dstLeftCenter.x - 12, dstLeftCenter.y - 4);
    path.moveTo(dstLeftCenter.x, dstLeftCenter.y);
    path.lineTo(dstLeftCenter.x - 12, dstLeftCenter.y + 4);
  }

  void topCenterArrow(Path path, Vector2 dstTopCenter) {
    path.lineTo(dstTopCenter.x - 4, dstTopCenter.y - 12);
    path.moveTo(dstTopCenter.x, dstTopCenter.y);
    path.lineTo(dstTopCenter.x + 4, dstTopCenter.y - 12);
  }

  void rightCenterArrow(Path path, Vector2 dstRightCenter) {
    path.lineTo(dstRightCenter.x + 12, dstRightCenter.y - 4);
    path.moveTo(dstRightCenter.x, dstRightCenter.y);
    path.lineTo(dstRightCenter.x + 12, dstRightCenter.y + 4);
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
