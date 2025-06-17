import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

extension LiquidGlassWidget<T extends Widget> on T {
  Widget asLiquidGlass(
      {Key? key,
      LiquidShape? shape,
      bool glassContainsChild = true,
      double blur = 0,
      Clip clipBehavior = Clip.hardEdge,
      LiquidGlassSettings settings = const LiquidGlassSettings()}) {
    return LiquidGlass(
      key: key,
      shape:
          shape ?? LiquidRoundedSuperellipse(borderRadius: Radius.circular(50)),
      glassContainsChild: glassContainsChild,
      blur: blur,
      clipBehavior: clipBehavior,
      settings: settings,
      child: this,
    );
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

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final LiquidShape? shape;
  final bool glassContainsChild;
  final double blur;
  final Clip clipBehavior;
  final LiquidGlassSettings settings;

  const LiquidGlassContainer(
      {super.key,
      this.shape,
      this.glassContainsChild = true,
      this.blur = 0,
      this.clipBehavior = Clip.hardEdge,
      this.settings = const LiquidGlassSettings(),
      required this.child});

  @override
  Widget build(BuildContext context) {
    return child.asLiquidGlass(
        shape: shape,
        glassContainsChild: glassContainsChild,
        blur: blur,
        clipBehavior: clipBehavior,
        settings: settings);
  }
}
