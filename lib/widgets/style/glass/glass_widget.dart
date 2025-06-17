import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

/// glass的实现，使用比较方便，调用asGlass
class GlassContainer extends StatelessWidget {
  final Widget child;

  final bool enabled;

  final double blurX;

  final double blurY;

  final Color tintColor;

  final bool frosted;

  final BorderRadius clipBorderRadius;

  final Clip clipBehaviour;

  final TileMode tileMode;

  final CustomClipper<RRect>? clipper;

  const GlassContainer(
      {super.key,
      this.enabled = false,
      this.blurX = 10.0,
      this.blurY = 10.0,
      this.tintColor = Colors.white,
      this.frosted = true,
      this.clipBorderRadius = BorderRadius.zero,
      this.clipBehaviour = Clip.antiAlias,
      this.tileMode = TileMode.clamp,
      this.clipper,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return child.asGlass(
        enabled: enabled,
        blurX: blurX,
        blurY: blurY,
        tintColor: tintColor,
        tileMode: tileMode,
        frosted: frosted,
        clipBehaviour: clipBehaviour,
        clipBorderRadius: clipBorderRadius,
        clipper: clipper);
  }
}
