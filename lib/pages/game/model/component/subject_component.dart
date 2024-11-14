import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/plugin/painter/line/dash_painter.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

class SubjectComponent extends RectangleComponent with ModelNodeComponent {
  static final normalStrokePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final currentStrokePaint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

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

  @override
  Future<void> onUpdate() async {
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
    if (subject.name == modelProjectController.currentSubjectName.value) {
      dashPainter.paint(canvas, path, currentStrokePaint);
    } else {
      dashPainter.paint(canvas, path, normalStrokePaint);
    }
  }
}
