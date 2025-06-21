import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_effect/liquid_glass_buttons.dart';
import 'package:liquid_glass_effect/liquid_glass_card.dart';
import 'package:liquid_glass_effect/liquid_glass_theme.dart';
import 'package:liquid_glass_effect/liquid_glass_widgets.dart';
import 'package:liquid_glass_effect/models/liquid_glass_config.dart';

buildThemeData() {
  LiquidGlassConfig glassConfig = LiquidGlassConfig(
    blurAmount: 15.0,
    highlightIntensity: 0.3,
    noiseOpacity: 0.0,
    highlightColor: Colors.white,
    noiseColor: Colors.white,
  );
  ThemeData themeData = createLiquidGlassTheme(
      config: glassConfig, colorScheme: myself.colorScheme);
  ThemeData darkThemeData = createLiquidGlassTheme(
      config: glassConfig, colorScheme: myself.darkColorScheme);
  myself.setThemeData(themeData: themeData, darkThemeData: darkThemeData);
}

extension LiquidGlassEffectWidget<T extends Widget> on T {
  Widget asLiquidGlassEffect(
      {Key? key,
      double? height,
      double? width,
      double? blurAmount = 15,
      double? noiseOpacity = 0.0,
      double? highlightIntensity = 0.3,
      Color? highlightColor,
      Color? noiseColor,
      ImageProvider<Object>? backgroundImageProvider,
      Gradient? backgroundGradient,
      BoxFit backgroundFit = BoxFit.cover,
      Alignment backgroundAlignment = Alignment.center}) {
    return SizedBox(
        height: height,
        width: width,
        child: LiquidGlassBackground(
          key: key,
          blurAmount: blurAmount,
          noiseOpacity: noiseOpacity,
          highlightIntensity: highlightIntensity,
          highlightColor: highlightColor,
          noiseColor: noiseColor,
          backgroundImageProvider: backgroundImageProvider,
          backgroundGradient: backgroundGradient,
          backgroundFit: backgroundFit,
          backgroundAlignment: backgroundAlignment,
          child: this,
        ));
  }
}

class LiquidGlassEffectContainer extends StatelessWidget {
  final double? height;
  final double? width;
  final Widget child;
  final double? blurAmount;
  final double? noiseOpacity;
  final double? highlightIntensity;
  final Color? highlightColor;
  final Color? noiseColor;
  final ImageProvider? backgroundImageProvider;
  final Gradient? backgroundGradient;
  final BoxFit backgroundFit;
  final Alignment backgroundAlignment;

  const LiquidGlassEffectContainer({
    super.key,
    required this.child,
    this.blurAmount = 15,
    this.noiseOpacity = 0.0,
    this.highlightIntensity = 0.3,
    this.highlightColor,
    this.noiseColor,
    this.backgroundImageProvider,
    this.backgroundGradient,
    this.backgroundFit = BoxFit.cover,
    this.backgroundAlignment = Alignment.center,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return child.asLiquidGlassEffect(
      height: height,
      width: width,
      blurAmount: blurAmount,
      noiseOpacity: noiseOpacity,
      highlightIntensity: highlightIntensity,
      highlightColor: highlightColor,
      noiseColor: noiseColor,
      backgroundImageProvider: backgroundImageProvider,
      backgroundGradient: backgroundGradient,
      backgroundFit: backgroundFit,
      backgroundAlignment: backgroundAlignment,
    );
  }
}

class LiquidGlassEffectCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? baseColor;
  final double? blurAmount;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final double elevation;
  final Color? shadowColor;
  final Duration animationDuration;
  final double scaleFactor;
  final bool enableHoverEffect;

  const LiquidGlassEffectCard({
    super.key,
    required this.child,
    this.borderRadius = 14.0,
    this.baseColor,
    this.blurAmount,
    this.padding,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1.0,
    this.elevation = 0,
    this.shadowColor,
    this.animationDuration = const Duration(milliseconds: 300),
    this.scaleFactor = 1.03,
    this.enableHoverEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
        borderRadius: borderRadius,
        baseColor: baseColor,
        blurAmount: blurAmount,
        padding: padding,
        onTap: onTap,
        borderColor: borderColor,
        borderWidth: borderWidth,
        elevation: elevation,
        shadowColor: shadowColor,
        animationDuration: animationDuration,
        scaleFactor: scaleFactor,
        enableHoverEffect: enableHoverEffect,
        child: child);
  }
}

class LiquidGlassEffectButton extends LiquidGlassElevatedButton {
  const LiquidGlassEffectButton({
    super.key,
    required super.onPressed,
    required super.child,
    super.style,
    super.autofocus = false,
    super.clipBehavior = Clip.none,
  });
}

class LiquidGlassEffectOutlinedButton extends LiquidGlassOutlinedButton {
  const LiquidGlassEffectOutlinedButton({
    super.key,
    required super.onPressed,
    required super.child,
    super.style,
    super.autofocus = false,
    super.clipBehavior = Clip.none,
  });
}

class LiquidGlassEffectBackground extends LiquidGlassBackground {
  const LiquidGlassEffectBackground({
    super.key,
    required super.child,
    super.blurAmount,
    super.noiseOpacity,
    super.highlightIntensity,
    super.highlightColor,
    super.noiseColor,
    super.backgroundImageProvider,
    super.backgroundGradient,
    super.backgroundFit = BoxFit.cover,
    super.backgroundAlignment = Alignment.center,
  });
}
