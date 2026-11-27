import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:flutter/material.dart';

/// ios 26样式的玻璃效果组件
/// 把组件变成透镜
/// LiquidGlassButton — refracts the content behind it. Anywhere on Impeller; on Skia place it inside a LiquidGlassView (frosted fallback without one).
/// LiquidGlassSlider — jelly thumb that refracts the track as it moves. Self-contained: it owns its background, so it works anywhere on both Impeller and Skia — no LiquidGlassView needed.
/// LiquidGlassToggle — refracts its own track. Self-contained, so it works anywhere on both Impeller and Skia — no LiquidGlassView needed.
/// LiquidGlassAppBar — refracts the content behind it. Anywhere on Impeller; needs a LiquidGlassView on Skia.
/// LiquidGlassBottomNavBar — refracts the content behind it. On Skia, use it inside a LiquidGlassScaffold (which provides the LiquidGlassView). To place it anywhere on Impeller, use the LiquidGlassBottomNavBar.withImpeller(...) constructor.
/// LiquidGlassTabBar — refracts the content behind it. Anywhere on Impeller; needs a LiquidGlassView on Skia.
/// LiquidGlassScaffold — a Scaffold-style layout that owns the glass pipeline (its own LiquidGlassView), so its child lenses refract the body anywhere on both engines.
/// LiquidGlassDraggable — a drag wrapper for any lens; inherits whatever the lens it wraps requires.
/// LiquidGlassJelly — the squash/stretch physics as a reusable widget; inherits whatever the content it wraps requires.
extension LiquidGlassLensWidget<T extends Widget> on T {
  Widget asLiquidGlassLens({
    Key? key,
    double height = double.infinity,
    double width = double.infinity,
    LiquidGlassCornerStyle cornerStyle =
        LiquidGlassCornerStyle.continuousRoundedRectangle,
    double cornerRadius = 50.0,
    LiquidGlassClipQuality clipQuality =
        LiquidGlassClipQuality.roundedRectangle,
    LiquidGlassLight? specular,
    LiquidGlassLight? glow,
    double refractionIndex = 1.1,
    double refractionWidth = 12.0,
    double magnification = 1.0,
    double dispersion = 0,
    double saturation = 1.0,
    double blur = 0.0,
    Color color = const Color(0x00000000),
    LiquidGlassShadow? shadow,
    LiquidGlassAdaptivity? adaptivity,
    bool liteGlass = false,
    bool? useImpellerBackdrop,
    bool visibility = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(0),
  }) {
    LiquidGlassShape shape = LiquidGlassShape(
      cornerStyle: cornerStyle,
      cornerRadius: cornerRadius,
      clipQuality: clipQuality,
    );
    LiquidGlassStyle style = LiquidGlassStyle(
      shape: shape,
      specular: specular,
      glow: glow,
      refractionIndex: refractionIndex,
      refractionWidth: refractionWidth,
      magnification: magnification,
      dispersion: dispersion,
      saturation: saturation,
      blur: blur,
      color: color,
      shadow: shadow,
      adaptivity: adaptivity,
      liteGlass: liteGlass,);
    return SizedBox(
        width: width,
        height: height,
        child: LiquidGlassLens(
          style: style,
          visibility: visibility,
          useImpellerBackdrop: useImpellerBackdrop,
          child: Padding(
              padding: padding,
              child: Center(
                child: this,
              )),
        ));
  }
}

/// ios 26样式的玻璃效果的容器
/// 必须有背景组件，比如Image，透镜组件列表
class LiquidGlassLensContainer extends StatelessWidget {
  final LiquidGlassViewController viewController = LiquidGlassViewController();
  final LiquidGlassController lensController = LiquidGlassController();

  final Widget backgroundWidget;

  final double? height;

  final double? width;

  final double pixelRatio;

  final bool useSync;

  final bool realTimeCapture;

  final LiquidGlassRefreshRate refreshRate;

  final Widget child;

  LiquidGlassLensContainer({super.key,
    this.height,
    this.width,
    this.pixelRatio = 1.0,
    this.useSync = true,
    this.realTimeCapture = true,
    this.refreshRate = LiquidGlassRefreshRate.deviceRefreshRate,
    required this.backgroundWidget,
    required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: height,
        width: width,
        child: LiquidGlassView(
            controller: viewController,
            backgroundWidget: backgroundWidget,
            pixelRatio: pixelRatio,
            useSync: useSync,
            realTimeCapture: realTimeCapture,
            refreshRate: refreshRate,
            child: child.asLiquidGlassLens()));
  }
}
