import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

extension LiquidGlassWidget<T extends Widget> on T {
  Widget asStyle(
      {Key? key,
      double? height,
      double? width,
      LiquidShape? shape,
      bool glassContainsChild = true,
      double blur = 15,
      Clip clipBehavior = Clip.hardEdge,
      LiquidGlassSettings settings = const LiquidGlassSettings()}) {
    return SizedBox(
        height: height,
        width: width,
        child: LiquidGlass(
          key: key,
          shape: shape ??
              LiquidRoundedSuperellipse(borderRadius: Radius.circular(0)),
          glassContainsChild: glassContainsChild,
          blur: blur,
          clipBehavior: clipBehavior,
          settings: settings,
          child: this,
        ));
  }

  /// 多个LiquidGlass.inLayer widgets的混合
  Widget asLiquidGlassLayer(
      {Key? key, LiquidGlassSettings settings = const LiquidGlassSettings()}) {
    return LiquidGlassLayer(
      key: key,
      settings: settings,
      child: this,
    );
  }
}

class PlatformStyleContainer extends LiquidGlass {
  final double? height;
  final double? width;
  final LiquidGlassSettings settings;

  const PlatformStyleContainer(
      {super.key,
      this.height,
      this.width,
      super.shape =
          const LiquidRoundedSuperellipse(borderRadius: Radius.circular(0)),
      super.glassContainsChild = true,
      super.blur = 15,
      super.clipBehavior = Clip.hardEdge,
      this.settings = const LiquidGlassSettings(),
      required super.child});

  @override
  Widget build(BuildContext context) {
    return child.asStyle(
        key: key,
        height: height,
        width: width,
        shape: shape,
        glassContainsChild: glassContainsChild,
        blur: blur,
        clipBehavior: clipBehavior,
        settings: settings);
  }
}
