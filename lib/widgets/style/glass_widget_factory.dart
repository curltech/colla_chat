import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

final defaultLinearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xFFffffff).withOpacity(0.1),
      const Color(0xFFFFFFFF).withOpacity(0.05),
    ],
    stops: const [
      0.1,
      1,
    ]);
final defaultBorderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    const Color(0xFFffffff).withOpacity(0.5),
    const Color((0xFFFFFFFF)).withOpacity(0.5),
  ],
);

class GlassWidgetFactory extends WidgetFactory {
  Widget buildSizedBox({
    Key? key,
    Widget? child,
    AlignmentGeometry? alignment = Alignment.bottomCenter,
    EdgeInsetsGeometry? padding,
    BoxShape shape = BoxShape.rectangle,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    required double width,
    required double height,
    double borderRadius = 20,
    LinearGradient? linearGradient,
    double border = 0,
    double blur = 20,
    LinearGradient? borderGradient,
  }) {
    return GlassmorphicContainer(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius,
      blur: blur,
      alignment: Alignment.bottomCenter,
      border: border,
      linearGradient: linearGradient ?? defaultLinearGradient,
      borderGradient: borderGradient ?? defaultBorderGradient,
      transform: transform,
      margin: margin,
      constraints: constraints,
      shape: shape,
      padding: padding,
      child: child,
    );
  }

  @override
  Widget buildContainer({
    Key? key,
    Widget? child,
    AlignmentGeometry? alignment = Alignment.bottomCenter,
    EdgeInsetsGeometry? padding,
    BoxShape shape = BoxShape.rectangle,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    double borderRadius = 20,
    LinearGradient? linearGradient,
    double border = 0,
    double blur = 20,
    LinearGradient? borderGradient,
    int? flex = 1,
  }) {
    return Column(children: [
      GlassmorphicFlexContainer(
        key: key,
        flex: flex,
        borderRadius: borderRadius,
        blur: blur,
        alignment: Alignment.bottomCenter,
        border: border,
        linearGradient: linearGradient ?? defaultLinearGradient,
        borderGradient: borderGradient ?? defaultBorderGradient,
        transform: transform,
        margin: margin,
        constraints: constraints,
        shape: shape,
        padding: padding,
        child: child,
      )
    ]);
  }
}

final GlassWidgetFactory glassWidgetFactory = GlassWidgetFactory();
