import 'dart:ui' as ui;

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/model_flame_game.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/plugin/painter/line/dash_painter.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// [NodeRelationshipComponent] 在src节点和dst关系节点之间画关系的连线
class NodeRelationshipComponent extends PositionComponent
    with TapCallbacks, HoverCallbacks, HasGameReference<ModelFlameGame> {
  final strokePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeWidth = 1.0;
  final selectedStrokePaint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true
    ..strokeWidth = 2.0;

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

    /// 源位置
    double srcX = srcNodeFrameComponent.position.x;
    double srcY = srcNodeFrameComponent.position.y;

    /// 源大小
    double srcHeight = srcNodeFrameComponent.size.y;
    double srcWidth = srcNodeFrameComponent.size.x;

    /// 源四个中心的位置
    Vector2 srcTopCenter = Vector2(srcX + srcWidth / 2, srcY);
    Vector2 srcLeftCenter = Vector2(srcX, srcY + srcHeight / 2);
    Vector2 srcRightCenter = Vector2(srcX + srcWidth, srcY + srcHeight / 2);
    Vector2 srcBottomCenter = Vector2(srcX + srcWidth / 2, srcY + srcHeight);

    if (nodeRelationship.dst == null) {
      return;
    }
    NodeFrameComponent? dstNodeFrameComponent =
        nodeRelationship.dst!.nodeFrameComponent;
    if (dstNodeFrameComponent == null) {
      return;
    }

    /// 源大小
    double dstX = dstNodeFrameComponent.position.x;
    double dstY = dstNodeFrameComponent.position.y;

    /// 源大小
    double dstHeight = dstNodeFrameComponent.size.y;
    double dstWidth = dstNodeFrameComponent.size.x;

    /// 源四个中心的位置
    Vector2 dstTopCenter = Vector2(dstX + dstWidth / 2, dstY);
    Vector2 dstLeftCenter = Vector2(dstX, dstY + dstHeight / 2);
    Vector2 dstRightCenter = Vector2(dstX + dstWidth, dstY + dstHeight / 2);
    Vector2 dstBottomCenter = Vector2(dstX + dstWidth / 2, dstY + dstHeight);

    Path path = Path();
    if (srcNodeFrameComponent.modelNode == dstNodeFrameComponent.modelNode) {
      selfLine(path, srcBottomCenter, srcWidth, srcRightCenter);
      rightCenterArrow(path, srcRightCenter);
      selfCardinality(canvas, srcBottomCenter, srcRightCenter);
      if (isHovered) {
        priority = 3;
        canvas.drawPath(path, selectedStrokePaint);
      } else {
        priority = 1;
        canvas.drawPath(path, strokePaint);
      }

      return;
    }
    if (srcX + srcWidth < dstX) {
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
    } else if (dstX + srcWidth < srcX) {
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
      if (isHovered ||
          modelProjectController.selectedRelationship.value ==
              nodeRelationship) {
        priority = 3;
        dashPainter.paint(canvas, path, selectedStrokePaint);
      } else {
        priority = 1;
        dashPainter.paint(canvas, path, strokePaint);
      }
    } else {
      if (isHovered ||
          modelProjectController.selectedRelationship.value ==
              nodeRelationship) {
        priority = 3;
        canvas.drawPath(path, selectedStrokePaint);
      } else {
        priority = 1;
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  void _drawLine(Path path, List<Vector2> vertices) {
    if (vertices.isEmpty) {
      return;
    }
    Vector2 point0 = vertices[0];
    path.moveTo(point0.x, point0.y);

    /// 贝塞尔曲线
    if (vertices.length == 2) {
      /// 直线
      Vector2 point1 = vertices[1];
      path.lineTo(point1.x, point1.y);
    } else if (vertices.length == 3) {
      /// 二次贝塞尔曲线
      Vector2 point1 = vertices[1];
      Vector2 point2 = vertices[2];
      path.quadraticBezierTo(point1.x, point1.y, point2.x, point2.y);
    } else if (vertices.length == 4) {
      /// 三次贝塞尔曲线
      Vector2 point1 = vertices[1];
      Vector2 point2 = vertices[2];
      Vector2 point3 = vertices[3];
      path.cubicTo(point1.x, point1.y, point2.x, point2.y, point3.x, point3.y);
    } else if (vertices.length == 5) {
      /// 三次贝塞尔曲线
      Vector2 point1 = vertices[1];
      Vector2 point2 = vertices[2];
      Vector2 point3 = vertices[3];
      Vector2 point4 = vertices[4];
      path.cubicTo(point2.x, point2.y, point3.x, point3.y, point4.x, point4.y);
      // path.quadraticBezierTo(point1.x, point1.y, point2.x, point2.y);
      // path.quadraticBezierTo(point3.x, point3.y, point4.x, point4.y);
    } else {
      /// 折线
      for (int i = 1; i < vertices.length; ++i) {
        Vector2 point = vertices[i];
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
          Offset(srcLeftCenter.x + (dstRightCenter.x - srcLeftCenter.x) / 2 + 4,
              srcLeftCenter.y + (dstRightCenter.y - srcLeftCenter.y) / 2 - 8));
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
          Offset(srcTopCenter.x + (dstBottomCenter.x - srcTopCenter.x) / 2,
              srcTopCenter.y + (dstBottomCenter.y - srcTopCenter.y) / 2 - 16));
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
              srcRightCenter.x + (dstLeftCenter.x - srcRightCenter.x) / 2 + 4,
              srcRightCenter.y + (dstLeftCenter.y - srcRightCenter.y) / 2 - 8));
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
              srcBottomCenter.x + (dstTopCenter.x - srcBottomCenter.x) / 2,
              srcBottomCenter.y +
                  (dstTopCenter.y - srcBottomCenter.y) / 2 -
                  16));
    }
  }

  void selfLine(Path path, Vector2 srcBottomCenter, double width,
      Vector2 srcRightCenter) {
    vertices = [
      srcBottomCenter,
      Vector2(srcBottomCenter.x, srcBottomCenter.y + 30),
      Vector2(srcBottomCenter.x + width, srcBottomCenter.y + 30),
      Vector2(srcBottomCenter.x + width, srcRightCenter.y),
      Vector2(srcRightCenter.x, srcRightCenter.y)
    ];
    _drawLine(path, vertices);
  }

  void selfCardinality(
      Canvas canvas, Vector2 srcBottomCenter, Vector2 srcRightCenter) {
    int? srcCardinality = nodeRelationship.srcCardinality;
    int? dstCardinality = nodeRelationship.dstCardinality;
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
    paragraph.layout(const ui.ParagraphConstraints(width: 60));
    canvas.drawParagraph(paragraph, offset);
  }

  double arrowWidth = 10;
  double arrowHeight = 4;

  void bottomCenterArrow(Path path, Vector2 dstBottomCenter) {
    path.lineTo(dstBottomCenter.x - arrowHeight, dstBottomCenter.y + arrowWidth);
    path.moveTo(dstBottomCenter.x, dstBottomCenter.y);
    path.lineTo(dstBottomCenter.x + arrowHeight, dstBottomCenter.y + arrowWidth);
  }

  void leftCenterArrow(Path path, Vector2 dstLeftCenter) {
    path.lineTo(dstLeftCenter.x - arrowWidth, dstLeftCenter.y - arrowHeight);
    path.moveTo(dstLeftCenter.x, dstLeftCenter.y);
    path.lineTo(dstLeftCenter.x - arrowWidth, dstLeftCenter.y + arrowHeight);
  }

  void topCenterArrow(Path path, Vector2 dstTopCenter) {
    path.lineTo(dstTopCenter.x - arrowHeight, dstTopCenter.y - arrowWidth);
    path.moveTo(dstTopCenter.x, dstTopCenter.y);
    path.lineTo(dstTopCenter.x + arrowHeight, dstTopCenter.y - arrowWidth);
  }

  void rightCenterArrow(Path path, Vector2 dstRightCenter) {
    path.lineTo(dstRightCenter.x + arrowWidth, dstRightCenter.y - arrowHeight);
    path.moveTo(dstRightCenter.x, dstRightCenter.y);
    path.lineTo(dstRightCenter.x + arrowWidth, dstRightCenter.y + arrowHeight);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    modelProjectController.selectedRelationship.value = nodeRelationship;
  }

  @override
  Future<void> onLongTapDown(TapDownEvent event) async {
    modelProjectController.selectedRelationship.value = nodeRelationship;
    indexWidgetProvider.push('relationship_edit');
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
      break;
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
