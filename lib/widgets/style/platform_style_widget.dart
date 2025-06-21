import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/style/glass/glass_widget.dart';
import 'package:colla_chat/widgets/style/glass/liquid_glass_effect_widget.dart';
import 'package:colla_chat/widgets/style/neumorphic/neumorphic_widget.dart';
import 'package:flutter/material.dart';

enum PlatformStyle { material, glass, liquidGlass, neumorphic, fluent }

extension PlatformStyleWidget<T extends Widget> on T {
  Widget asStyle({
    Key? key,
    double? height,
    double? width,
    double blur = defaultBlur,
    Color tintColor = Colors.white,
    bool frosted = false,
    BorderRadius clipBorderRadius = BorderRadius.zero,
    Clip clipBehaviour = Clip.antiAlias,
    TileMode tileMode = TileMode.clamp,
    CustomClipper<RRect>? clipper,
  }) {
    Widget child;
    switch (myself.platformStyle) {
      case PlatformStyle.material:
        child = this;
      case PlatformStyle.glass:
        child = asGlassWidget(
            enabled: true,
            height: height,
            width: width,
            blur: blur,
            tintColor: tintColor,
            tileMode: tileMode,
            frosted: frosted,
            clipBehaviour: clipBehaviour,
            clipBorderRadius: clipBorderRadius,
            clipper: clipper);
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
            tintColor: tintColor,
            tileMode: tileMode,
            frosted: frosted,
            clipBehaviour: clipBehaviour,
            clipBorderRadius: clipBorderRadius,
            clipper: clipper);
    }

    return child;
  }
}
