import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_position_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/node_relationship_edit_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// [NodeRelationshipComponent] 在src节点和dst关系节点之间画关系的连线
class NodeRelationshipComponent extends PositionComponent
    with TapCallbacks, HoverCallbacks, HasGameRef<ModelFlameGame> {
  final strokePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final selectedStrokePaint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final TextPaint normal = TextPaint(
    style: TextStyle(
      color: BasicPalette.black.color,
      fontSize: 10.0,
    ),
  );

  NodeRelationshipComponent({required this.nodeRelationship}) : super() {
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
    Vector2 dstLeftCenter = Vector2(dstX, dstY + dstHeight / 2);
    Vector2 dstRightCenter =
        Vector2(dstX + Project.nodeWidth, dstY + dstHeight / 2);
    Vector2 dstBottomCenter =
        Vector2(dstX + Project.nodeWidth / 2, dstY + dstHeight);

    Path path = Path();
    if (srcNodePositionComponent.modelNode ==
        dstNodePositionComponent.modelNode) {
      selfLine(path, srcBottomCenter, srcRightCenter);
      rightCenterArrow(path, srcRightCenter);
      if (isHovered) {
        canvas.drawPath(path, selectedStrokePaint);
      } else {
        canvas.drawPath(path, strokePaint);
      }

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
    if (isHovered) {
      canvas.drawPath(path, selectedStrokePaint);
    } else {
      canvas.drawPath(path, strokePaint);
    }
  }

  void leftBottomLine(
      Path path, Vector2 srcLeftCenter, Vector2 dstBottomCenter) {
    path.moveTo(srcLeftCenter.x, srcLeftCenter.y);
    path.lineTo(dstBottomCenter.x, srcLeftCenter.y);
    path.lineTo(dstBottomCenter.x, dstBottomCenter.y);
  }

  void leftBottomCardinality(Vector2 srcLeftCenter, Vector2 dstBottomCenter) {
    int srcCardinality = nodeRelationship.srcCardinality;
    int dstCardinality = nodeRelationship.dstCardinality;
    add(TextComponent(
        text: '$srcCardinality:$dstCardinality',
        textRenderer: normal,
        position: Vector2(srcLeftCenter.x, srcLeftCenter.y)));
  }

  void leftRightLine(Path path, Vector2 srcLeftCenter, Vector2 dstRightCenter) {
    path.moveTo(srcLeftCenter.x, srcLeftCenter.y);
    path.lineTo(srcLeftCenter.x - (srcLeftCenter.x - dstRightCenter.x) / 2,
        srcLeftCenter.y);
    path.lineTo(srcLeftCenter.x - (srcLeftCenter.x - dstRightCenter.x) / 2,
        dstRightCenter.y);
    path.lineTo(dstRightCenter.x, dstRightCenter.y);
  }

  void leftRightCardinality(Vector2 srcLeftCenter, Vector2 dstRightCenter) {
    int srcCardinality = nodeRelationship.srcCardinality;
    int dstCardinality = nodeRelationship.dstCardinality;
    add(TextComponent(
        text: '$srcCardinality:$dstCardinality',
        textRenderer: normal,
        position: Vector2(
            srcLeftCenter.x - (srcLeftCenter.x - dstRightCenter.x) / 2 - 24,
            dstRightCenter.y)));
  }

  void topBottomLine(Path path, Vector2 srcTopCenter, Vector2 dstBottomCenter) {
    path.moveTo(srcTopCenter.x, srcTopCenter.y);
    path.lineTo(srcTopCenter.x,
        srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2);
    path.lineTo(dstBottomCenter.x,
        srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2);
    path.lineTo(dstBottomCenter.x, dstBottomCenter.y);
  }

  void topBottomCardinality(Vector2 srcTopCenter, Vector2 dstBottomCenter) {
    int srcCardinality = nodeRelationship.srcCardinality;
    int dstCardinality = nodeRelationship.dstCardinality;
    add(TextComponent(
        text: '$srcCardinality:$dstCardinality',
        textRenderer: normal,
        position: Vector2(srcTopCenter.x + 36,
            srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2)));
  }

  void rightLeftLine(Path path, Vector2 srcRightCenter, Vector2 dstLeftCenter) {
    path.moveTo(srcRightCenter.x, srcRightCenter.y);
    path.lineTo(srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
        srcRightCenter.y);
    path.lineTo(srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
        dstLeftCenter.y);
    path.lineTo(dstLeftCenter.x, dstLeftCenter.y);
  }

  void rightLeftCardinality(Vector2 srcRightCenter, Vector2 dstLeftCenter) {
    int srcCardinality = nodeRelationship.srcCardinality;
    int dstCardinality = nodeRelationship.dstCardinality;
    add(TextComponent(
        text: '$srcCardinality:$dstCardinality',
        textRenderer: normal,
        position: Vector2(
            srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2 - 36,
            srcRightCenter.y - 16)));
  }

  void bottomTopLine(Path path, Vector2 srcBottomCenter, Vector2 dstTopCenter) {
    path.moveTo(srcBottomCenter.x, srcBottomCenter.y);
    path.lineTo(srcBottomCenter.x,
        srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
    path.lineTo(dstTopCenter.x,
        srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2);
    path.lineTo(dstTopCenter.x, dstTopCenter.y);
  }

  void bottomTopCardinality(Vector2 srcBottomCenter, Vector2 dstTopCenter) {
    int srcCardinality = nodeRelationship.srcCardinality;
    int dstCardinality = nodeRelationship.dstCardinality;
    add(TextComponent(
        text: '$srcCardinality:$dstCardinality',
        textRenderer: normal,
        position: Vector2(
            srcBottomCenter.x + 36,
            srcBottomCenter.y +
                (dstTopCenter.y - srcBottomCenter.y) / 2 -
                16)));
  }

  void selfLine(Path path, Vector2 srcBottomCenter, Vector2 srcRightCenter) {
    path.moveTo(srcBottomCenter.x, srcBottomCenter.y);
    path.lineTo(srcBottomCenter.x, srcBottomCenter.y + 30);
    path.lineTo(srcBottomCenter.x + Project.nodeWidth, srcBottomCenter.y + 30);
    path.lineTo(srcBottomCenter.x + Project.nodeWidth, srcRightCenter.y);
    path.lineTo(srcRightCenter.x, srcRightCenter.y);
  }

  void selfCardinality(Vector2 srcBottomCenter, Vector2 srcRightCenter) {
    int srcCardinality = nodeRelationship.srcCardinality;
    int dstCardinality = nodeRelationship.dstCardinality;
    add(TextComponent(
        text: '$srcCardinality:$dstCardinality',
        textRenderer: normal,
        position: Vector2(srcBottomCenter.x + Project.nodeWidth - 36,
            srcBottomCenter.y + 16)));
  }

  void bottomCenterArrow(Path path, Vector2 dstBottomCenter) {
    path.lineTo(dstBottomCenter.x - 2, dstBottomCenter.y + 6);
    path.moveTo(dstBottomCenter.x, dstBottomCenter.y);
    path.lineTo(dstBottomCenter.x + 2, dstBottomCenter.y + 6);
  }

  void leftCenterArrow(Path path, Vector2 dstLeftCenter) {
    path.lineTo(dstLeftCenter.x - 6, dstLeftCenter.y - 2);
    path.moveTo(dstLeftCenter.x, dstLeftCenter.y);
    path.lineTo(dstLeftCenter.x - 6, dstLeftCenter.y + 2);
  }

  void topCenterArrow(Path path, Vector2 dstTopCenter) {
    path.lineTo(dstTopCenter.x - 2, dstTopCenter.y - 6);
    path.moveTo(dstTopCenter.x, dstTopCenter.y);
    path.lineTo(dstTopCenter.x + 2, dstTopCenter.y - 6);
  }

  void rightCenterArrow(Path path, Vector2 dstRightCenter) {
    path.lineTo(dstRightCenter.x + 6, dstRightCenter.y - 2);
    path.moveTo(dstRightCenter.x, dstRightCenter.y);
    path.lineTo(dstRightCenter.x + 6, dstRightCenter.y + 2);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    NodeRelationship? m =
        await DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
      return NodeRelationshipEditWidget(
        nodeRelationship: nodeRelationship,
      );
    });
    if (m != null) {}
  }
}
