import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/plugin/painter/line/dash_painter.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

class SubjectComponent extends RectangleComponent {
  static final strokePaint = Paint()
    ..color = Colors.yellow.shade50
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  late TextComponent textComponent;

  Subject subject;

  SubjectComponent(
    this.subject, {
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
  }) {
    Rect rect = subject.rect;
    position = Vector2(rect.left, rect.top);
    size = rect.size.toVector2();
  }

  @override
  Future<void> onLoad() async {
    final textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14.0,
      ),
    );
    textComponent = TextComponent(
        text: subject.name,
        textRenderer: textPaint,
        position: Vector2(10.0, 10.0));
    add(textComponent);
  }

  onUpdate() {
    textComponent.text = subject.name;
    Rect rect = subject.rect;
    position = Vector2(rect.left, rect.top);
    size = rect.size.toVector2();
  }

  @override
  void render(Canvas canvas) {
    DashPainter dashPainter = const DashPainter();
    Path path = Path();
    path.addRect(Rect.fromLTWH(0, 0, width, height));
    dashPainter.paint(canvas, path, strokePaint);
  }
}
