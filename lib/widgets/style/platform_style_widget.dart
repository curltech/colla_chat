import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/style/glass/glass_kit_widget.dart';
import 'package:colla_chat/widgets/style/glass/glass_widget.dart';
import 'package:colla_chat/widgets/style/glass/liquid_glass_effect_widget.dart';
import 'package:colla_chat/widgets/style/neumorphic/neumorphic_widget.dart';
import 'package:flutter/material.dart';

enum PlatformStyle {
  material,
  glass,
  glassKit,
  liquidGlass,
  neumorphic,
  fluent
}

const double defaultBlur = 15;
const double defaultOpacity = 0.12;
const double defaultFrostedOpacity = 0.12;
const BorderRadius defaultBorderRadius = BorderRadius.zero;
const Color defaultShadowColor = Colors.black;

extension PlatformStyleWidget<T extends Widget> on T {
  Widget asStyle(
      {Key? key,
      double? height,
      double? width,
      double blur = defaultBlur,
      Color color = Colors.white,
      BorderRadius borderRadius = defaultBorderRadius,
      bool frosted = false,
      Clip clipBehaviour = Clip.antiAlias,
      TileMode tileMode = TileMode.clamp,
      CustomClipper<RRect>? clipper,
      AlignmentGeometry? alignment,
      Matrix4? transform,
      AlignmentGeometry? transformAlignment,
      EdgeInsetsGeometry? padding,
      EdgeInsetsGeometry? margin,
      Gradient? gradient,
      double? borderWidth,
      Gradient? borderGradient,
      Color? borderColor,
      double? elevation,
      Color? shadowColor = defaultShadowColor,
      BoxShape shape = BoxShape.rectangle,
      double? frostedOpacity = defaultFrostedOpacity}) {
    Widget child;
    switch (myself.platformStyle) {
      case PlatformStyle.material:
        child = SizedBox(
          height: height,
          width: width,
        );
      case PlatformStyle.glass:
        child = asGlassWidget(
            enabled: true,
            height: height,
            width: width,
            blur: blur,
            tintColor: color,
            tileMode: tileMode,
            frosted: frosted,
            clipBehaviour: clipBehaviour,
            clipBorderRadius: borderRadius,
            clipper: clipper);
      case PlatformStyle.glassKit:
        child = asGlassKit(
          height: height,
          width: width,
          blur: blur,
          isFrostedGlass: frosted,
          frostedOpacity: frostedOpacity,
          alignment: alignment,
          transform: transform,
          transformAlignment: transformAlignment,
          padding: padding,
          margin: margin,
          color: color,
          gradient: gradient,
          borderRadius: borderRadius,
          borderGradient: borderGradient,
          shadowColor: shadowColor,
          shape: shape,
        );
      case PlatformStyle.liquidGlass:
        child =
            asLiquidGlassEffect(height: height, width: width, blurAmount: blur);
      case PlatformStyle.neumorphic:
        child = asNeumorphicStyle(
          height: height,
          width: width,
        );
      default:
        child = asGlassWidget(
            enabled: true,
            height: height,
            width: width,
            blur: blur,
            tintColor: color,
            tileMode: tileMode,
            frosted: frosted,
            clipBehaviour: clipBehaviour,
            clipBorderRadius: borderRadius,
            clipper: clipper);
    }

    return child;
  }
}
