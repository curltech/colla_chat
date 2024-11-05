import 'dart:ui' as ui;

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/node_relationship_edit_widget.dart';
import 'package:colla_chat/plugin/painter/line/dash_painter.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// [NodeRelationshipComponent] 在src节点和dst关系节点之间画关系的连线
class NodeRelationshipComponent extends PositionComponent
    with TapCallbacks, HoverCallbacks, HasGameRef<ModelFlameGame> {
  final strokePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeWidth = 1.0;
  final selectedStrokePaint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeWidth = 1.0;

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

  List<Vector2> vertices = [];

  @override
  Future<void> onLoad() async {}

  @override
  void render(Canvas canvas) {
    if (nodeRelationship.src == null) {
      return;
    }
    NodeFrameComponent? srcNodeFrameComponent =
        nodeRelationship.src!.nodeFrameComponent;
    if (srcNodeFrameComponent == null) {
      return;
    }
    double srcX = srcNodeFrameComponent.position.x;
    double srcY = srcNodeFrameComponent.position.y;
    double srcHeight = srcNodeFrameComponent.size.y;
    Vector2 srcTopCenter = Vector2(srcX + Project.nodeWidth / 2, srcY);
    Vector2 srcLeftCenter = Vector2(srcX, srcY + srcHeight / 2);
    Vector2 srcRightCenter =
        Vector2(srcX + Project.nodeWidth, srcY + srcHeight / 2);
    Vector2 srcBottomCenter =
        Vector2(srcX + Project.nodeWidth / 2, srcY + srcHeight);

    if (nodeRelationship.dst == null) {
      return;
    }
    NodeFrameComponent? dstNodeFrameComponent =
        nodeRelationship.dst!.nodeFrameComponent;
    if (dstNodeFrameComponent == null) {
      return;
    }
    double dstX = dstNodeFrameComponent.position.x;
    double dstY = dstNodeFrameComponent.position.y;
    double dstHeight = dstNodeFrameComponent.size.y;
    Vector2 dstTopCenter = Vector2(dstX + Project.nodeWidth / 2, dstY);
    Vector2 dstLeftCenter = Vector2(dstX, dstY + dstHeight / 2);
    Vector2 dstRightCenter =
        Vector2(dstX + Project.nodeWidth, dstY + dstHeight / 2);
    Vector2 dstBottomCenter =
        Vector2(dstX + Project.nodeWidth / 2, dstY + dstHeight);

    Path path = Path();
    if (srcNodeFrameComponent.modelNode == dstNodeFrameComponent.modelNode) {
      selfLine(path, srcBottomCenter, srcRightCenter);
      rightCenterArrow(path, srcRightCenter);
      selfCardinality(canvas, srcBottomCenter, srcRightCenter);
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
          bottomTopCardinality(canvas, srcBottomCenter, dstTopCenter);
        } else {
          rightLeftLine(path, srcRightCenter, dstLeftCenter);
          leftCenterArrow(path, dstLeftCenter);
          rightLeftCardinality(canvas, srcRightCenter, dstLeftCenter);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY - 30) {
          // src在dst的全下边
          topBottomLine(path, srcTopCenter, dstBottomCenter);
          bottomCenterArrow(path, dstBottomCenter);
          topBottomCardinality(canvas, srcTopCenter, dstBottomCenter);
        } else {
          rightLeftLine(path, srcRightCenter, dstLeftCenter);
          leftCenterArrow(path, dstLeftCenter);
          rightLeftCardinality(canvas, srcRightCenter, dstLeftCenter);
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
          bottomTopCardinality(canvas, srcBottomCenter, dstTopCenter);
        } else {
          leftRightLine(path, srcLeftCenter, dstRightCenter);
          rightCenterArrow(path, dstRightCenter);
          leftRightCardinality(canvas, srcLeftCenter, dstRightCenter);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY - 30) {
          // src在dst的全下边
          topBottomLine(path, srcTopCenter, dstBottomCenter);
          bottomCenterArrow(path, dstBottomCenter);
          topBottomCardinality(canvas, srcTopCenter, dstBottomCenter);
        } else {
          leftRightLine(path, srcLeftCenter, dstRightCenter);
          rightCenterArrow(path, dstRightCenter);
          leftRightCardinality(canvas, srcLeftCenter, dstRightCenter);
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
          bottomTopCardinality(canvas, srcBottomCenter, dstTopCenter);
        } else {
          bottomTopLine(path, srcBottomCenter, dstTopCenter);
          topCenterArrow(path, dstTopCenter);
          bottomTopCardinality(canvas, srcBottomCenter, dstTopCenter);
        }
      } else {
        // src在dst的下边
        if (dstY + dstHeight < srcY) {
          // src在dst的全下边
          topBottomLine(path, srcTopCenter, dstBottomCenter);
          bottomCenterArrow(path, dstBottomCenter);
          topBottomCardinality(canvas, srcTopCenter, dstBottomCenter);
        } else {
          leftBottomLine(path, srcLeftCenter, dstBottomCenter);
          topCenterArrow(path, dstTopCenter);
          leftBottomCardinality(canvas, srcLeftCenter, dstBottomCenter);
        }
      }
    }

    if (nodeRelationship.relationshipType == RelationshipType.reference.name) {
      DashPainter dashPainter = const DashPainter();
      if (isHovered) {
        dashPainter.paint(canvas, path, selectedStrokePaint);
      } else {
        dashPainter.paint(canvas, path, strokePaint);
      }
    } else {
      if (isHovered) {
        canvas.drawPath(path, selectedStrokePaint);
      } else {
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  void _drawLine(Path path, List<Vector2> vertices) {
    for (int i = 0; i < vertices.length; ++i) {
      Vector2 point = vertices[i];
      if (i == 0) {
        path.moveTo(point.x, point.y);
      } else {
        path.lineTo(point.x, point.y);
      }
    }
  }

  void leftBottomLine(
      Path path, Vector2 srcLeftCenter, Vector2 dstBottomCenter) {
    vertices = [
      srcLeftCenter,
      Vector2(dstBottomCenter.x, srcLeftCenter.y),
      Vector2(dstBottomCenter.x, dstBottomCenter.y),
    ];
    _drawLine(path, vertices);
  }

  void leftBottomCardinality(
      Canvas canvas, Vector2 srcLeftCenter, Vector2 dstBottomCenter) {
    int? srcCardinality = nodeRelationship.srcCardinality;
    int? dstCardinality = nodeRelationship.dstCardinality;
    if (srcCardinality != null && dstCardinality != null) {
      _drawCardinality(canvas, '$srcCardinality:$dstCardinality',
          Offset(srcLeftCenter.x, srcLeftCenter.y));
    }
  }

  void leftRightLine(Path path, Vector2 srcLeftCenter, Vector2 dstRightCenter) {
    vertices = [
      Vector2(srcLeftCenter.x, srcLeftCenter.y),
      Vector2(srcLeftCenter.x - (srcLeftCenter.x - dstRightCenter.x) / 2,
          srcLeftCenter.y),
      Vector2(srcLeftCenter.x - (srcLeftCenter.x - dstRightCenter.x) / 2,
          dstRightCenter.y),
      Vector2(dstRightCenter.x, dstRightCenter.y)
    ];
    _drawLine(path, vertices);
  }

  void leftRightCardinality(
      Canvas canvas, Vector2 srcLeftCenter, Vector2 dstRightCenter) {
    int? srcCardinality = nodeRelationship.srcCardinality;
    int? dstCardinality = nodeRelationship.dstCardinality;
    if (srcCardinality != null && dstCardinality != null) {
      _drawCardinality(
          canvas,
          '$srcCardinality:$dstCardinality',
          Offset(
              srcLeftCenter.x - (srcLeftCenter.x - dstRightCenter.x) / 2 - 24,
              dstRightCenter.y));
    }
  }

  void topBottomLine(Path path, Vector2 srcTopCenter, Vector2 dstBottomCenter) {
    vertices = [
      Vector2(srcTopCenter.x, srcTopCenter.y),
      Vector2(srcTopCenter.x,
          srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2),
      Vector2(dstBottomCenter.x,
          srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2),
      Vector2(dstBottomCenter.x, dstBottomCenter.y)
    ];
    _drawLine(path, vertices);
  }

  void topBottomCardinality(
      Canvas canvas, Vector2 srcTopCenter, Vector2 dstBottomCenter) {
    int? srcCardinality = nodeRelationship.srcCardinality;
    int? dstCardinality = nodeRelationship.dstCardinality;
    if (srcCardinality != null && dstCardinality != null) {
      _drawCardinality(
          canvas,
          '$srcCardinality:$dstCardinality',
          Offset(srcTopCenter.x + 36,
              srcTopCenter.y - (srcTopCenter.y - dstBottomCenter.y) / 2));
    }
  }

  void rightLeftLine(Path path, Vector2 srcRightCenter, Vector2 dstLeftCenter) {
    vertices = [
      Vector2(srcRightCenter.x, srcRightCenter.y),
      Vector2(srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
          srcRightCenter.y),
      Vector2(srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2,
          dstLeftCenter.y),
      Vector2(dstLeftCenter.x, dstLeftCenter.y)
    ];
    _drawLine(path, vertices);
  }

  void rightLeftCardinality(
      Canvas canvas, Vector2 srcRightCenter, Vector2 dstLeftCenter) {
    int? srcCardinality = nodeRelationship.srcCardinality;
    int? dstCardinality = nodeRelationship.dstCardinality;
    if (srcCardinality != null && dstCardinality != null) {
      _drawCardinality(
          canvas,
          '$srcCardinality:$dstCardinality',
          Offset(
              srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2 - 36,
              srcRightCenter.y - 16));
    }
  }

  void bottomTopLine(Path path, Vector2 srcBottomCenter, Vector2 dstTopCenter) {
    vertices = [
      Vector2(srcBottomCenter.x, srcBottomCenter.y),
      Vector2(srcBottomCenter.x,
          srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2),
      Vector2(dstTopCenter.x,
          srcBottomCenter.y + (dstTopCenter.y - srcBottomCenter.y) / 2),
      Vector2(dstTopCenter.x, dstTopCenter.y)
    ];
    _drawLine(path, vertices);
  }

  void bottomTopCardinality(
      Canvas canvas, Vector2 srcBottomCenter, Vector2 dstTopCenter) {
    int? srcCardinality = nodeRelationship.srcCardinality;
    int? dstCardinality = nodeRelationship.dstCardinality;
    if (srcCardinality != null && dstCardinality != null) {
      _drawCardinality(
          canvas,
          '$srcCardinality:$dstCardinality',
          Offset(
              srcBottomCenter.x + 36,
              srcBottomCenter.y +
                  (dstTopCenter.y - srcBottomCenter.y) / 2 -
                  16));
    }
  }

  void selfLine(Path path, Vector2 srcBottomCenter, Vector2 srcRightCenter) {
    vertices = [
      srcBottomCenter,
      Vector2(srcBottomCenter.x, srcBottomCenter.y + 30),
      Vector2(srcBottomCenter.x + Project.nodeWidth, srcBottomCenter.y + 30),
      Vector2(srcBottomCenter.x + Project.nodeWidth, srcRightCenter.y),
      Vector2(srcRightCenter.x, srcRightCenter.y)
    ];
    _drawLine(path, vertices);
  }

  void selfCardinality(
      Canvas canvas, Vector2 srcBottomCenter, Vector2 srcRightCenter) {
    int? srcCardinality = 1; //nodeRelationship.srcCardinality;
    int? dstCardinality = 1; //nodeRelationship.dstCardinality;
    if (srcCardinality != null && dstCardinality != null) {
      _drawCardinality(canvas, '$srcCardinality:$dstCardinality',
          Offset(srcRightCenter.x, srcBottomCenter.y + 16));
    }
  }

  _drawCardinality(Canvas canvas, String text, Offset offset) {
    ui.ParagraphStyle style =
        ui.ParagraphStyle(textAlign: TextAlign.start, fontSize: 10.0);
    ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(style);
    paragraphBuilder.pushStyle(
        ui.TextStyle(color: isHovered ? Colors.yellow : Colors.black));
    paragraphBuilder.addText(text);
    ui.Paragraph paragraph = paragraphBuilder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 30));
    canvas.drawParagraph(paragraph, offset);
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

  @override
  bool containsLocalPoint(Vector2 point) {
    for (int i = 1; i < vertices.length; ++i) {
      Vector2 from = vertices[i - 1];
      Vector2 to = vertices[i];
      bool contain = _containsPoint(from, to, point);
      if (contain) {
        return contain;
      }
    }
    return false;
  }

  bool between(double v, double m, double n) {
    return ((v > m && v < n) || (v < m && v > n));
  }

  bool _containsPoint(Vector2 from, Vector2 to, Vector2 point,
      {double epsilon = 15.0}) {
    if (from.x == to.x) {
      double absX = (point.x - from.x).abs();
      if (absX < epsilon && between(point.y, from.y, to.y)) {
        return true;
      }
    }
    if (from.y == to.y) {
      double absY = (point.y - from.y).abs();
      if (absY < epsilon && between(point.x, from.x, to.x)) {
        return true;
      }
    }

    return false;
  }
}
