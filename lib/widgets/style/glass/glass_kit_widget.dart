import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/style/platform_style_widget.dart';
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart' as glass;

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

extension GlassKitWidget<T extends Widget> on T {
  Widget asGlassKit(
      {Key? key,
      double? height,
      double? width,
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
    return glass.GlassContainer(
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
      shadowColor: shadowColor,
      shape: shape,
      child: this,
    );
  }
}

/// glass的实现，使用比较方便，调用asGlass
class GlassKitContainer extends glass.GlassContainer {
  GlassKitContainer(
      {super.key,
      super.height,
      super.width,
      super.isFrostedGlass = false,
      super.alignment,
      super.transform,
      super.transformAlignment,
      super.padding,
      super.margin,
      super.gradient,
      super.color,
      super.borderRadius = defaultBorderRadius,
      super.borderWidth,
      super.borderGradient,
      super.borderColor,
      super.blur = defaultBlur,
      super.elevation,
      super.shadowColor,
      super.shape = BoxShape.rectangle,
      super.frostedOpacity = defaultFrostedOpacity,
      required super.child});

  @override
  Widget build(BuildContext context) {
    return child!.asGlassKit(
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
        shadowColor: myself.secondary,
        shape: shape);
  }
}
