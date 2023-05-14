import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

final defaultLinearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      myself.primary.withOpacity(AppOpacity.lgOpacity),
      myself.primary.withOpacity(AppOpacity.xlOpacity),
    ],
    stops: const [
      AppOpacity.lgOpacity,
      AppOpacity.xsOpacity,
    ]);
final defaultBorderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    myself.primary.withOpacity(AppOpacity.lgOpacity),
    myself.primary.withOpacity(AppOpacity.lgOpacity),
  ],
);

const double blur = 4;
const double border = 0;
const double borderRadius = 0;

class GlassWidgetFactory extends WidgetFactory {
  @override
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
    double borderRadius = borderRadius,
    LinearGradient? linearGradient,
    double border = border,
    double blur = blur,
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
    double borderRadius = borderRadius,
    LinearGradient? linearGradient,
    double border = border,
    double blur = blur,
    LinearGradient? borderGradient,
    int? flex = 1,
  }) {
    return Column(children: [
      GlassmorphicFlexContainer(
        key: key,
        flex: flex,
        borderRadius: borderRadius,
        blur: blur,
        alignment: alignment,
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
