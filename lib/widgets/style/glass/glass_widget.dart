import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

extension GlassWidget<T extends Widget> on T {
  Widget asStyle({
    Key? key,
    bool enabled = true,
    double blurX = 15.0,
    double blurY = 15.0,
    Color tintColor = Colors.white,
    bool frosted = true,
    BorderRadius clipBorderRadius = BorderRadius.zero,
    Clip clipBehaviour = Clip.antiAlias,
    TileMode tileMode = TileMode.clamp,
    CustomClipper<RRect>? clipper,
  }) {
    return asGlass(
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

/// glass的实现，使用比较方便，调用asGlass
class PlatformStyleContainer extends StatelessWidget {
  final Widget child;

  final double? height;

  final double? width;

  final bool enabled;

  final double blurX;

  final double blurY;

  final Color tintColor;

  final bool frosted;

  final BorderRadius clipBorderRadius;

  final Clip clipBehaviour;

  final TileMode tileMode;

  final CustomClipper<RRect>? clipper;

  const PlatformStyleContainer(
      {super.key,
      this.height,
      this.width,
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
    return SizedBox(
        height: height,
        width: width,
        child: child.asGlass(
            enabled: enabled,
            blurX: blurX,
            blurY: blurY,
            tintColor: tintColor,
            tileMode: tileMode,
            frosted: frosted,
            clipBehaviour: clipBehaviour,
            clipBorderRadius: clipBorderRadius,
            clipper: clipper));
  }
}
