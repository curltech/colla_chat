import 'package:colla_chat/constant/base.dart';
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

/// glass_kit实现，实际上只提供了一个glass化的Container
final defaultLinearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withAlpha(AppOpacity.lgOpacity),
      Colors.white.withAlpha(AppOpacity.xlOpacity),
    ],
    stops: const [
      0.3,
      0.9,
    ]);
final defaultBorderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Colors.white.withAlpha(AppOpacity.lgOpacity),
    Colors.white.withAlpha(AppOpacity.lgOpacity),
  ],
);

const double defaultBlur = 20;
const double defaultFrostedOpacity = 0.12;
const BorderRadius defaultBorderRadius = BorderRadius.zero;
final Color defaultShadowColor = Colors.black.withAlpha(50);

extension GlassKitWidget<T extends Widget> on T {
  Widget asGlassKit(
      {Key? key,
      required double height,
      required double width,
      bool isFrostedGlass = false,
      AlignmentGeometry? alignment,
      Matrix4? transform,
      AlignmentGeometry? transformAlignment,
      EdgeInsetsGeometry? padding,
      EdgeInsetsGeometry? margin,
      Gradient? gradient,
      Color? color,
      BorderRadius? borderRadius = defaultBorderRadius,
      double? borderWidth,
      Gradient? borderGradient,
      Color? borderColor,
      double? blur = defaultBlur,
      double? elevation,
      Color? shadowColor,
      BoxShape shape = BoxShape.rectangle,
      double? frostedOpacity = defaultFrostedOpacity}) {
    return GlassContainer(
      key: key,
      height: height,
      width: width,
      isFrostedGlass: isFrostedGlass,
      frostedOpacity: frostedOpacity,
      blur: blur,
      alignment: alignment,
      transform: transform,
      transformAlignment: transformAlignment,
      padding: padding,
      margin: margin,
      color: color,
      gradient: gradient ?? defaultLinearGradient,
      borderRadius: borderRadius,
      borderGradient: borderGradient ?? defaultBorderGradient,
      shadowColor: shadowColor ?? defaultShadowColor,
      shape: shape,
      child: this,
    );
  }
}

/// glass的实现，使用比较方便，调用asGlass
class GlassKitContainer extends StatelessWidget {
  final Widget child;

  final double height;
  final double width;
  final bool isFrostedGlass;

  final AlignmentGeometry? alignment;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? color;
  final BorderRadius? borderRadius;

  final double? borderWidth;
  final Gradient? borderGradient;
  final Color? borderColor;
  final double? blur;

  final double? elevation;
  final Color? shadowColor;
  final BoxShape shape;
  final double? frostedOpacity;

  const GlassKitContainer(
      {super.key,
      required this.height,
      required this.width,
      this.isFrostedGlass = false,
      this.alignment,
      this.transform,
      this.transformAlignment,
      this.padding,
      this.margin,
      this.gradient,
      this.color,
      this.borderRadius = defaultBorderRadius,
      this.borderWidth,
      this.borderGradient,
      this.borderColor,
      this.blur = defaultBlur,
      this.elevation,
      this.shadowColor,
      this.shape = BoxShape.rectangle,
      this.frostedOpacity = defaultFrostedOpacity,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return child.asGlassKit(
        key: key,
        height: height,
        width: width,
        isFrostedGlass: isFrostedGlass,
        frostedOpacity: frostedOpacity,
        blur: blur,
        alignment: alignment,
        transform: transform,
        transformAlignment: transformAlignment,
        padding: padding,
        margin: margin,
        color: color,
        gradient: defaultLinearGradient,
        borderRadius: borderRadius,
        borderGradient: defaultBorderGradient,
        shadowColor: shadowColor ?? defaultShadowColor,
        shape: shape);
  }
}
