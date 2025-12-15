import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// ios 26样式的玻璃效果组件
extension LiquidGlassLensWidget<T extends Widget> on T {
  LiquidGlass asLiquidGlassLens(
    LiquidGlassController lensController, {
    Key? key,
    double height = double.infinity,
    double width = double.infinity,
    LiquidGlassAlignPosition position =
        const LiquidGlassAlignPosition(alignment: Alignment.center),
    double magnification = 1,
    bool enableInnerRadiusTransparent = false,
    double distortion = 0.2,
    double distortionWidth = 30,
    double diagonalFlip = 0,
    bool draggable = false,
    LiquidGlassShape shape = const RoundedRectangleShape(),
    LiquidGlassBlur blur = const LiquidGlassBlur(),
    bool visibility = true,
    Color color = Colors.transparent,
    bool outOfBoundaries = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(0),
  }) {
    return LiquidGlass(
      controller: lensController,
      position: position,
      width: width,
      height: height,
      magnification: magnification,
      enableInnerRadiusTransparent: enableInnerRadiusTransparent,
      diagonalFlip: diagonalFlip,
      distortion: distortion,
      distortionWidth: distortionWidth,
      draggable: draggable,
      outOfBoundaries: outOfBoundaries,
      color: color,
      blur: blur,
      shape: shape,
      visibility: visibility,
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
class LiquidGlassLensContainer extends StatelessWidget {
  final LiquidGlassViewController viewController = LiquidGlassViewController();
  final LiquidGlassController lensController = LiquidGlassController();

  final Widget backgroundWidget;

  final List<Widget> children;

  final double? height;

  final double? width;

  final double pixelRatio;

  final bool useSync;

  final bool realTimeCapture;

  final LiquidGlassRefreshRate refreshRate;

  final List<LiquidGlass> lenses = [];

  LiquidGlassLensContainer(
      {super.key,
      this.height,
      this.width,
      this.pixelRatio = 1.0,
      this.useSync = true,
      this.realTimeCapture = true,
      this.refreshRate = LiquidGlassRefreshRate.deviceRefreshRate,
      required this.children,
      required this.backgroundWidget}) {
    for (var child in children) {
      lenses.add(child.asLiquidGlassLens(lensController));
    }
  }

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
            children: lenses));
  }
}
