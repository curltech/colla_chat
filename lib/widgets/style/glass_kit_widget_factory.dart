import 'package:colla_chat/widgets/style/glass_widget_factory.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

class GlassKitWidgetFactory extends WidgetFactory {
  @override
  Widget buildSizedBox({
    Key? key,
    required double height,
    required double width,
    AlignmentGeometry? alignment,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    Gradient? gradient,
    BorderRadius? borderRadius,
    double? borderWidth,
    Color? borderColor,
    Gradient? borderGradient,
    double? blur,
    bool? isFrostedGlass,
    double? frostedOpacity,
    double? elevation,
    Color? shadowColor,
    BoxShape shape = BoxShape.rectangle,
    Widget? child,
  }) {
    return GlassContainer(
      key: key,
      width: width,
      height: height,
      alignment: alignment,
      transform: transform,
      transformAlignment: transformAlignment,
      padding: padding,
      margin: margin,
      color: color,
      gradient: gradient ?? defaultLinearGradient,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      borderColor: borderColor,
      borderGradient: borderGradient ?? defaultBorderGradient,
      blur: blur,
      isFrostedGlass: isFrostedGlass,
      frostedOpacity: frostedOpacity,
      elevation: elevation,
      shadowColor: shadowColor,
      shape: shape,
      child: child,
    );
  }

  @override
  Widget buildContainer({
    Key? key,
    AlignmentGeometry? alignment,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    Gradient? gradient,
    BorderRadius? borderRadius,
    double? borderWidth,
    Color? borderColor,
    Gradient? borderGradient,
    double? blur,
    bool? isFrostedGlass,
    double? frostedOpacity,
    double? elevation,
    Color? shadowColor,
    BoxShape shape = BoxShape.rectangle,
    Widget? child,
  }) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return GlassContainer(
        key: key,
        height: constraints.maxHeight,
        width: constraints.maxWidth,
        alignment: alignment,
        transform: transform,
        transformAlignment: transformAlignment,
        padding: padding,
        margin: margin,
        color: color,
        gradient: gradient ?? defaultLinearGradient,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        borderColor: borderColor,
        borderGradient: borderGradient ?? defaultBorderGradient,
        blur: blur,
        isFrostedGlass: isFrostedGlass,
        frostedOpacity: frostedOpacity,
        elevation: elevation,
        shadowColor: shadowColor,
        shape: shape,
        child: child,
      );
    });
  }
}

final GlassKitWidgetFactory glassKitWidgetFactory = GlassKitWidgetFactory();
