import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';

extension LiquidGlassDesignWidget<T extends Widget> on T {
  Widget asLiquidGlassDesign(
      {Key? key,
      BuildContext? context,
      double? height,
      double? width,
      double blurStrength = 30.0,
      Color? baseColor,
      Color? borderColor,
      double borderRadius = 20.0,
      double borderWidth = 0.5,
      EdgeInsets? padding = const EdgeInsets.all(16.0),
      EdgeInsets? margin = const EdgeInsets.symmetric(vertical: 8.0),
      double vibrancy = 0.7,
      List<BoxShadow>? boxShadow,
      double surfaceOpacity = 0.08,
      double reflectionIntensity = 0.4,
      bool animate = true}) {
    Widget content = LiquidGlassEffect(
        key: key,
        blurStrength: blurStrength,
        baseColor: baseColor,
        borderColor: borderColor,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        padding: padding,
        margin: margin,
        vibrancy: vibrancy,
        boxShadow: boxShadow,
        surfaceOpacity: surfaceOpacity,
        reflectionIntensity: reflectionIntensity,
        child: this);
    if (animate) {
      context ??= appDataProvider.context;
      if (context != null) {
        content = LiquidTransition(
          animation: CurvedAnimation(
            parent: AnimationController(
              duration: const Duration(milliseconds: 300),
              vsync: Navigator.of(context),
            )..forward(),
            curve: Curves.easeInOut,
          ),
          child: content,
        );
      }
    }
    if (this is AppBar) {}
    if (height != null || width != null) {
      return SizedBox(height: height, width: width, child: content);
    }
    return content;
  }
}

class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget appBar;

  final Color? color;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool animate;
  final String? semanticsLabel;

  const LiquidGlassAppBar({
    super.key,
    required this.appBar,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.animate = true,
    this.semanticsLabel,
  });

  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    final theme = context
            .dependOnInheritedWidgetOfExactType<LiquidThemeProvider>()
            ?.theme ??
        const LiquidTheme();

    Widget content = LiquidGlassEffect(
      borderRadius: borderRadius ?? theme.borderRadius,
      baseColor: color ?? theme.primaryColor,
      padding: padding ?? theme.defaultPadding,
      margin: margin ?? theme.defaultMargin,
      child: appBar,
    );

    if (animate) {
      content = LiquidTransition(
        animation: CurvedAnimation(
          parent: AnimationController(
            duration: const Duration(milliseconds: 300),
            vsync: Navigator.of(context),
          )..forward(),
          curve: Curves.easeInOut,
        ),
        child: content,
      );
    }

    return Semantics(label: semanticsLabel ?? 'App Bar', child: content);
  }
}
