import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

const double defaultBlur = 15;

extension GlassWidget<T extends Widget> on T {
  Widget asGlassWidget({
    Key? key,
    double? height,
    double? width,
    bool enabled = true,
    double blur = defaultBlur,
    Color tintColor = Colors.white,
    bool frosted = false,
    BorderRadius clipBorderRadius = BorderRadius.zero,
    Clip clipBehaviour = Clip.antiAlias,
    TileMode tileMode = TileMode.clamp,
    CustomClipper<RRect>? clipper,
  }) {
    return SizedBox(
        height: height,
        width: width,
        child: asGlass(
            enabled: enabled,
            blurX: blur,
            blurY: blur,
            tintColor: tintColor,
            tileMode: tileMode,
            frosted: frosted,
            clipBehaviour: clipBehaviour,
            clipBorderRadius: clipBorderRadius,
            clipper: clipper));
  }
}

/// glass的实现，使用比较方便，调用asGlass
class GlassContainer extends StatelessWidget {
  final Widget child;

  final double? height;

  final double? width;

  final bool enabled;

  final double blur;

  final Color tintColor;

  final bool frosted;

  final BorderRadius clipBorderRadius;

  final Clip clipBehaviour;

  final TileMode tileMode;

  final CustomClipper<RRect>? clipper;

  const GlassContainer(
      {super.key,
      this.height,
      this.width,
      this.enabled = false,
      this.blur = defaultBlur,
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
            blurX: blur,
            blurY: blur,
            tintColor: tintColor,
            tileMode: tileMode,
            frosted: frosted,
            clipBehaviour: clipBehaviour,
            clipBorderRadius: clipBorderRadius,
            clipper: clipper));
  }
}
