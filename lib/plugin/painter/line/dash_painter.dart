import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

/// 虚线绘制器
// [step] the length of solid line 每段实线长
// [span] the space of each solid line  每段空格线长
// [pointCount] the point count of dash line  点划线的点数
// [pointWidth] the point width of dash line  点划线的点划长
class DashPainter {
  const DashPainter({
    this.step = 2,
    this.span = 2,
    this.pointCount = 0,
    this.pointWidth,
  });

  final double step;
  final double span;
  final int pointCount;
  final double? pointWidth;

  void paint(Canvas canvas, Path path, Paint paint) {
    final PathMetrics pms = path.computeMetrics();
    final double pointLineLength = pointWidth ?? paint.strokeWidth;
    final double partLength =
        step + span * (pointCount + 1) + pointCount * pointLineLength;

    for (var pm in pms) {
      final int count = pm.length ~/ partLength;
      for (int i = 0; i < count; i++) {
        canvas.drawPath(
          pm.extractPath(partLength * i, partLength * i + step),
          paint,
        );
        for (int j = 1; j <= pointCount; j++) {
          final start =
              partLength * i + step + span * j + pointLineLength * (j - 1);
          canvas.drawPath(
            pm.extractPath(start, start + pointLineLength),
            paint,
          );
        }
      }
      final double tail = pm.length % partLength;
      canvas.drawPath(pm.extractPath(pm.length - tail, pm.length), paint);
    }
  }
}

/// 虚线的装饰器，可以应用到其他组件比如组件的边框
class DashDecoration extends Decoration {
  final Gradient? gradient;

  final Color color;
  final double step;
  final double span;
  final int pointCount;
  final double? pointWidth;
  final Radius? radius;
  final double strokeWidth;

  const DashDecoration(
      {this.gradient,
      required this.color,
      this.step = 2,
      this.strokeWidth = 1,
      this.span = 2,
      this.pointCount = 0,
      this.pointWidth,
      this.radius});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      DashBoxPainter(this);
}

class DashBoxPainter extends BoxPainter {
  final DashDecoration _decoration;

  DashBoxPainter(this._decoration);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    if (configuration.size == null) {
      return;
    }

    Radius radius = _decoration.radius ?? Radius.zero;
    canvas.save();
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _decoration.color
      ..strokeWidth = _decoration.strokeWidth;
    final Path path = Path();

    canvas.translate(
      offset.dx + configuration.size!.width / 2,
      offset.dy + configuration.size!.height / 2,
    );

    final Rect zone = Rect.fromCenter(
      center: Offset.zero,
      width: configuration.size!.width,
      height: configuration.size!.height,
    );

    path.addRRect(RRect.fromRectAndRadius(
      zone,
      radius,
    ));

    if (_decoration.gradient != null) {
      paint.shader = _decoration.gradient!.createShader(zone);
    }

    DashPainter(
      span: _decoration.span,
      step: _decoration.step,
      pointCount: _decoration.pointCount,
      pointWidth: _decoration.pointWidth,
    ).paint(canvas, path, paint);
    canvas.restore();
  }
}
