import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

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
    double borderWidth = 1.0,
    Color? borderColor,
    double lightIntensity = 1.0,
    Color lightColor = const Color(0xB2FFFFFF),
    double lightDirection = 0.0,
    LiquidGlassLightMode lightMode = LiquidGlassLightMode.edge,
    LiquidGlassBorderType borderType = const OpticalBorder(),
    double saturation = 1.0,
    LiquidGlassBlur blur = const LiquidGlassBlur(),
    Color color = Colors.transparent,
    bool enableInnerRadiusTransparent = false,
    double distortion = 0.1,
    double distortionWidth = 30,
    double magnification = 1,
    double chromaticAberration = 0.003,
    LiquidGlassRefractionMode refractionMode =
        LiquidGlassRefractionMode.shapeRefraction,
    LiquidGlassRefractionType? refractionType,
    double diagonalFlip = 0,
    bool? useImpellerBackdrop,
    bool visibility = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(0),
  }) {
    LiquidGlassShape shape = LiquidGlassShape(
      cornerStyle: cornerStyle,
      cornerRadius: cornerRadius,
      clipQuality: clipQuality,
      borderWidth: borderWidth,
      borderColor: borderColor,
      lightIntensity: lightIntensity,
      lightColor: lightColor,
      lightDirection: lightDirection,
      lightMode: lightMode,
      borderType: borderType,
    );
    LiquidGlassAppearance appearance = LiquidGlassAppearance(
      saturation: saturation,
      blur: blur,
      color: color,
      enableInnerRadiusTransparent: enableInnerRadiusTransparent,
    );
    LiquidGlassRefraction refraction = LiquidGlassRefraction(
      distortion: distortion,
      distortionWidth: distortionWidth,
      magnification: magnification,
      chromaticAberration: chromaticAberration,
      refractionMode: refractionMode,
      refractionType: refractionType,
      diagonalFlip: diagonalFlip,
    );
    LiquidGlassStyle style = LiquidGlassStyle(
        shape: shape, appearance: appearance, refraction: refraction);
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

  LiquidGlassLensContainer(
      {super.key,
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
