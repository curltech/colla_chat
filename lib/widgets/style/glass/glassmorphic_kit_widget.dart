import 'package:colla_chat/constant/base.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphic_ui_kit/glassmorphic_ui_kit.dart';

/// glassmorphic_ui_kit实现，提供了多个个glass化的Widget
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

const double defaultBlur = 20;
const double defaultOpacity = 0.12;
const BorderRadius defaultBorderRadius = BorderRadius.zero;

extension GlassmorphicKitWidget<T extends Widget> on T {
  Widget asGlassmorphicKit(
      {Key? key,
      double? height,
      double? width,
      EdgeInsetsGeometry? padding,
      Gradient? gradient,
      Color? color,
      BorderRadius? borderRadius = defaultBorderRadius,
      BoxBorder? border,
      double blur = defaultBlur,
      double opacity = defaultOpacity}) {
    GlassButton(
      key: key,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      gradient: gradient ?? defaultLinearGradient,
      padding: padding,
      child: this,
    );
    GlassCard(
      width: width,
      height: height,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      gradient: gradient ?? defaultLinearGradient,
      padding: padding,
      child: this,
    );
    GlassDialog(
      blur: blur,
      borderRadius: borderRadius,
      gradient: gradient ?? defaultLinearGradient,
    );
    GlassBottomSheet(
      height: height,
      blur: blur,
      borderRadius: borderRadius,
      gradient: gradient ?? defaultLinearGradient,
      padding: padding,
      child: this,
    );
    GlassNavigationBar(
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      gradient: gradient ?? defaultLinearGradient,
      padding: padding,
      destinations: [],
      selectedIndex: 0,
    );
    GlassNavigationDrawer(
      width: width,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      gradient: gradient ?? defaultLinearGradient,
      padding: padding,
    );
    GlassProgressIndicator(
      blur: blur,
      opacity: opacity,
      gradient: gradient ?? defaultLinearGradient,
    );
    GlassSlider(
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      gradient: gradient ?? defaultLinearGradient,
      value: 0,
      onChanged: (double value) {},
    );
    GlassTextField(
      blur: blur,
      opacity: opacity,
      gradient: gradient ?? defaultLinearGradient,
    );

    return GlassContainer(
      key: key,
      width: width,
      height: height,
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      gradient: gradient ?? defaultLinearGradient,
      border: border,
      color: color,
      padding: padding,
      child: this,
    );
  }
}

/// glass的实现，使用比较方便，调用asGlass
class GlassmorphicKitContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final BoxBorder? border;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const GlassmorphicKitContainer(
      {super.key,
      this.width,
      this.height,
      this.blur = GlassConstants.defaultBlur,
      this.opacity = GlassConstants.defaultOpacity,
      this.borderRadius,
      this.gradient,
      this.border,
      this.color,
      this.padding,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return child.asGlassmorphicKit(
        key: key,
        height: height,
        width: width,
        opacity: opacity,
        blur: blur,
        padding: padding,
        color: color,
        border: border,
        gradient: defaultLinearGradient,
        borderRadius: borderRadius);
  }
}
