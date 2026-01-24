import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_effect/liquid_glass_buttons.dart';
import 'package:liquid_glass_effect/liquid_glass_card.dart';
import 'package:liquid_glass_effect/liquid_glass_theme.dart';
import 'package:liquid_glass_effect/liquid_glass_widgets.dart';
import 'package:liquid_glass_effect/models/liquid_glass_config.dart';

extension LiquidGlassEffectWidget<T extends Widget> on T {
  Widget asLiquidGlassEffect({
    Key? key,
    double? height,
    double? width,
    double? blurAmount = 15,
    double? noiseOpacity = 0.05,
    double? highlightIntensity = 0.3,
    Color? highlightColor,
    Color? noiseColor,
    ImageProvider<Object>? backgroundImageProvider,
    Gradient? backgroundGradient,
    BoxFit backgroundFit = BoxFit.cover,
    Alignment backgroundAlignment = Alignment.center,
    void Function()? onPressed,
    ButtonStyle? style,
    bool autofocus = false,
    Clip clipBehavior = Clip.none,
    double borderRadius = 14.0,
    Color? baseColor,
    EdgeInsets? padding,
    Color? borderColor,
    double borderWidth = 1.0,
    double elevation = 0,
    Color? shadowColor,
    Duration animationDuration = const Duration(milliseconds: 300),
    double scaleFactor = 1.0,
    bool enableHoverEffect = true,
  }) {
    if (this is ElevatedButton) {
      return LiquidGlassElevatedButton(
        key: key,
        onPressed: onPressed,
        child: this,
        style: style,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
      );
    }
    if (this is OutlinedButton) {
      return LiquidGlassOutlinedButton(
        key: key,
        onPressed: onPressed,
        child: this,
        style: style,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
      );
    }

    if (this is Container) {
      return SizedBox(
          height: height,
          width: width,
          child: LiquidGlassBackground(
            key: key,
            blurAmount: blurAmount,
            noiseOpacity: noiseOpacity,
            highlightIntensity: highlightIntensity,
            highlightColor: highlightColor ?? myself.primary,
            noiseColor: noiseColor ?? myself.secondary,
            backgroundImageProvider: backgroundImageProvider,
            backgroundGradient: backgroundGradient,
            backgroundFit: backgroundFit,
            backgroundAlignment: backgroundAlignment,
            child: this,
          ));
    }
    return SizedBox(
        height: height,
        width: width,
        child: LiquidGlassCard(
            key: key,
            borderRadius: borderRadius,
            baseColor: baseColor ?? myself.primary.withAlpha(32),
            blurAmount: blurAmount,
            padding: padding ?? EdgeInsets.all(0.0),
            onTap: onPressed,
            borderColor: borderColor ?? myself.primary.withAlpha(32),
            borderWidth: borderWidth,
            elevation: elevation,
            shadowColor: shadowColor ?? myself.secondary,
            animationDuration: animationDuration,
            scaleFactor: scaleFactor,
            enableHoverEffect: enableHoverEffect,
            child: this));
  }
}

class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget appBar;

  final double borderRadius;
  final Color? baseColor;
  final double? blurAmount;
  final EdgeInsets? padding;
  final Color? borderColor;
  final double borderWidth;
  final double elevation;
  final Color? shadowColor;
  final Duration animationDuration;
  final double scaleFactor;
  final bool enableHoverEffect;

  const LiquidGlassAppBar({
    super.key,
    required this.appBar,
    this.borderRadius = 0.0,
    this.baseColor,
    this.blurAmount,
    this.padding = EdgeInsets.zero,
    this.borderColor,
    this.borderWidth = 0.0,
    this.elevation = 0,
    this.shadowColor,
    this.animationDuration = const Duration(milliseconds: 300),
    this.scaleFactor = 1.03,
    this.enableHoverEffect = true,
  });

  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
        borderRadius: borderRadius,
        baseColor: baseColor ?? myself.primaryColor,
        blurAmount: blurAmount,
        padding: padding,
        borderColor: borderColor ?? myself.primaryColor,
        borderWidth: borderWidth,
        elevation: elevation,
        shadowColor: shadowColor ?? Colors.blueGrey,
        animationDuration: animationDuration,
        scaleFactor: scaleFactor,
        enableHoverEffect: enableHoverEffect,
        child: appBar);
  }
}
