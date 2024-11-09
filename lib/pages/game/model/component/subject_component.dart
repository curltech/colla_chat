import 'dart:ui';

import 'package:colla_chat/plugin/painter/line/dash_painter.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

class SubjectComponent extends RectangleComponent {
  static final strokePaint = Paint()
    ..color = Colors.yellow.shade50
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  SubjectComponent({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    super.paint,
    super.paintLayers,
    super.key,
  });

  factory SubjectComponent.fromRect(
    Rect rect, {
    Vector2? scale,
    double? angle,
    Anchor anchor = Anchor.topLeft,
    int? priority,
    Paint? paint,
    List<Paint>? paintLayers,
    ComponentKey? key,
    List<Component>? children,
  }) {
    return SubjectComponent(
      position: anchor == Anchor.topLeft
          ? rect.topLeft.toVector2()
          : Anchor.topLeft.toOtherAnchorPosition(
              rect.topLeft.toVector2(),
              anchor,
              rect.size.toVector2(),
            ),
      size: rect.size.toVector2(),
      scale: scale,
      angle: angle,
      anchor: anchor,
      priority: priority,
      paint: paint,
      paintLayers: paintLayers,
      key: key,
      children: children,
    );
  }

  @override
  void render(Canvas canvas) {
    DashPainter dashPainter = const DashPainter();
    Path path = Path();
    path.addRect(Rect.fromLTWH(position.x, position.y, width, height));
    dashPainter.paint(canvas, path, strokePaint);
  }
}
