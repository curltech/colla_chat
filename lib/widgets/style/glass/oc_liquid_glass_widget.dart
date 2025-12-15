import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

/// ios 26样式的玻璃效果组件
extension OCLiquidGlassWidget<T extends Widget> on T {
  Widget asOCLiquidGlass({
    Key? key,
    double height = double.infinity,
    double width = double.infinity,
    bool enabled = true,
    Color color = Colors.transparent,
    double borderRadius = 0.0,
    BoxShadow? shadow,
    Widget? child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(0),
  }) {
    return OCLiquidGlass(
      enabled: enabled,
      borderRadius: borderRadius,
      width: width,
      height: height,
      shadow: shadow,
      color: color,
      child: Padding(
          padding: padding,
          child: Center(
            child: this,
          )),
    );
  }
}

/// ios 26样式的玻璃效果的容器
/// 必须有背景组件，比如Image，透镜组建列表
class OCLiquidGlassContainer extends StatelessWidget {
  final Widget backgroundWidget;

  final List<Widget> children;

  final double? height;

  final double? width;

  // Shader uniform parameters - these control the visual appearance of the glass effect
  final double
      blendPx; // Edge blending distance in pixels for smooth transitions
  final double
      refractStrength; // Strength of light refraction (-1.0 to 1.0, negative = concave lens)
  final double
      distortFalloffPx; // Distance over which distortion effect fades out
  final double
      distortExponent; // Controls how sharply distortion falls off (higher = sharper)
  final double blurRadiusPx; // Base blur radius applied to the glass area

  // Specular highlight parameters - creates the shiny reflection on glass surface
  final double specAngle; // Light source angle for specular highlights
  final double specStrength; // Intensity of specular highlights
  final double specPower; // Sharpness of specular highlights (higher = sharper)
  final double specWidth; // Specular width in px

  // Light band effect - creates a bright band across the glass for realism
  final double lightbandOffsetPx; // Distance from edge where light band appears
  final double lightbandWidthPx; // Width of the light band effect
  final double lightbandStrength; // Intensity of the light band
  final Color lightbandColor; // Color of the light band

  late final OCLiquidGlassSettings settings;

  final List<Widget> lenses = [];

  OCLiquidGlassContainer({
    super.key,
    this.height,
    this.width,
    required this.children,
    required this.backgroundWidget,
    this.blendPx = 5,
    this.refractStrength = -0.06,
    this.distortFalloffPx = 45,
    this.distortExponent = 4,
    this.blurRadiusPx = 0,
    this.specAngle = 4,
    this.specStrength = 20.0,
    this.specPower = 100,
    this.specWidth = 10,
    this.lightbandOffsetPx = 10,
    this.lightbandWidthPx = 30,
    this.lightbandStrength = 0.9,
    this.lightbandColor = Colors.white,
  }) {
    settings = OCLiquidGlassSettings(
      blendPx: blendPx,
      refractStrength: refractStrength,
      distortFalloffPx: distortFalloffPx,
      distortExponent: distortExponent,
      blurRadiusPx: blurRadiusPx,
      specAngle: specAngle,
      specStrength: specStrength,
      specPower: specPower,
      specWidth: specWidth,
      lightbandOffsetPx: lightbandOffsetPx,
      lightbandWidthPx: lightbandWidthPx,
      lightbandStrength: lightbandStrength,
      lightbandColor: lightbandColor,
    );
    for (var child in children) {
      lenses.add(child.asOCLiquidGlass(child: child));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: height,
        width: width,
        child: Stack(children: [
          backgroundWidget,
          OCLiquidGlassGroup(settings: settings, child: Stack(children: lenses))
        ]));
  }
}
