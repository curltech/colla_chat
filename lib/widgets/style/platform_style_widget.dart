import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/style/glass/glass_kit_widget.dart';
import 'package:colla_chat/widgets/style/glass/glass_widget.dart';
import 'package:colla_chat/widgets/style/glass/liquid_glass_design_widget.dart';
import 'package:colla_chat/widgets/style/glass/liquid_glass_effect_widget.dart';
import 'package:colla_chat/widgets/style/glass/liquid_glass_lens_widget.dart';
import 'package:colla_chat/widgets/style/neumorphic/neumorphic_widget.dart';
import 'package:flutter/material.dart';

import 'package:colla_chat/widgets/style/glass/oc_liquid_glass_widget.dart';

enum PlatformStyle {
  material,
  glass,
  glassKit,
  liquidGlass,
  liquidGlassDesign,
  ocLiquidGlass,
  liquidGlassLens,
  neumorphic,
  fluent
}

const double defaultBlur = 15;
const double defaultOpacity = 0.12;
const double defaultFrostedOpacity = 0.12;
const BorderRadius defaultBorderRadius = BorderRadius.zero;

extension PlatformStyleWidget<T extends Widget> on T {
  Widget asStyle({
    Key? key,
    double? height,
    double? width,
    double blur = defaultBlur,
    Color? color,
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
    Color? shadowColor,
    BoxShape shape = BoxShape.rectangle,
    double? frostedOpacity = defaultFrostedOpacity,
    Widget? backgroundWidget,
  }) {
    Widget child;
    color = color ?? myself.primary;
    borderColor = borderColor ?? myself.primary;
    shadowColor = shadowColor ?? myself.secondary;
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
        child = asLiquidGlassEffect(
            height: height,
            width: width,
            padding: padding,
            borderRadius: borderRadius.topLeft.x,
            blurAmount: blur);
      case PlatformStyle.liquidGlassDesign:
        child = asLiquidGlassDesign(
            height: height,
            width: width,
            blurStrength: blur,
            surfaceOpacity: defaultOpacity);
      case PlatformStyle.ocLiquidGlass:
        child = OCLiquidGlassContainer(
          height: height,
          width: width,
          backgroundWidget: backgroundWidget ?? Container(),
          children: [this],
        );
      case PlatformStyle.liquidGlassLens:
        child = LiquidGlassLensContainer(
          height: height,
          width: width,
          backgroundWidget: backgroundWidget ?? Container(),
          children: [this],
        );
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
