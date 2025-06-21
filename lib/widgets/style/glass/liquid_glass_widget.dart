import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

extension LiquidGlassWidget<T extends Widget> on T {
  Widget asLiquidGlass(
      {Key? key,
      double? height,
      double? width,
      LiquidShape? shape,
      bool glassContainsChild = true,
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

class LiquidGlassContainer extends LiquidGlass {
  final double? height;
  final double? width;
  final LiquidGlassSettings settings;

  const LiquidGlassContainer(
      {super.key,
      this.height,
      this.width,
      super.shape =
          const LiquidRoundedSuperellipse(borderRadius: Radius.circular(0)),
      super.glassContainsChild = true,
      super.clipBehavior = Clip.hardEdge,
      this.settings = const LiquidGlassSettings(),
      required super.child});

  @override
  Widget build(BuildContext context) {
    return child.asLiquidGlass(
        key: key,
        height: height,
        width: width,
        shape: shape,
        glassContainsChild: glassContainsChild,
        clipBehavior: clipBehavior,
        settings: settings);
  }
}
