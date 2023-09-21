import 'package:colla_chat/widgets/style/glass/glassmorphism_widget_factory.dart';
import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

class GlassKitWidgetFactory extends WidgetFactory {
  Widget clearGlass({
    Key? key,
    required double height,
    required double width,
    AlignmentGeometry? alignment,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Gradient? gradient,
    Color? color,
    BorderRadius? borderRadius = borderRadius,
    double? borderWidth,
    Gradient? borderGradient,
    Color? borderColor,
    double? blur = blur,
    double? elevation,
    Color? shadowColor,
    BoxShape shape = BoxShape.rectangle,
    Widget? child,
  }) {
    return GlassContainer.clearGlass(
        key: key,
        height: height,
        width: width,
        alignment: alignment,
        transform: transform,
        transformAlignment: transformAlignment,
        padding: padding,
        margin: margin,
        gradient: gradient,
        color: color,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        borderGradient: borderGradient,
        borderColor: borderColor,
        blur: blur,
        elevation: elevation,
        shadowColor: shadowColor,
        shape: shape,
        child: child);
  }

  Widget frostedGlass({
    Key? key,
    required double height,
    required double width,
    AlignmentGeometry? alignment,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Gradient? gradient,
    Color? color,
    BorderRadius? borderRadius = borderRadius,
    double? borderWidth,
    Gradient? borderGradient,
    Color? borderColor,
    double? blur = blur,
    double? elevation,
    Color? shadowColor,
    BoxShape shape = BoxShape.rectangle,
    double? frostedOpacity,
    Widget? child,
  }) {
    return GlassContainer.frostedGlass(
        key: key,
        height: height,
        width: width,
        alignment: alignment,
        transform: transform,
        transformAlignment: transformAlignment,
        padding: padding,
        margin: margin,
        gradient: gradient,
        color: color,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        borderGradient: borderGradient,
        borderColor: borderColor,
        blur: blur,
        elevation: elevation,
        shadowColor: shadowColor,
        shape: shape,
        frostedOpacity: frostedOpacity,
        child: child);
  }

  @override
  Widget sizedBox({
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
    BorderRadius? borderRadius = borderRadius,
    double? borderWidth,
    Color? borderColor,
    Gradient? borderGradient,
    double? blur = blur,
    bool isFrostedGlass = false,
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
  Widget container({
    Key? key,
    AlignmentGeometry? alignment,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    Gradient? gradient,
    BorderRadius? borderRadius = borderRadius,
    double? borderWidth,
    Color? borderColor,
    Gradient? borderGradient,
    double? blur = blur,
    bool? isFrostedGlass = false,
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

  @override
  PreferredSizeWidget appBar(
      {Key? key,
      Widget? leading,
      Widget? title,
      bool? centerTitle,
      List<Widget>? actions}) {
    return glassmorphismWidgetFactory.appBar(
        key: key,
        leading: leading,
        title: title,
        centerTitle: centerTitle,
        actions: actions);
  }

  @override
  Widget bottomNavigationBar({
    Key? key,
    required List<BottomNavigationBarItem> items,
    int currentIndex = 0,
    Function(int p1)? onTap,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    double? selectedColorOpacity,
  }) {
    return glassmorphismWidgetFactory.bottomNavigationBar(
      key: key,
      items: items,
      currentIndex: currentIndex,
      selectedItemColor: selectedItemColor,
      selectedColorOpacity: selectedColorOpacity,
      onTap: onTap,
      unselectedItemColor: unselectedItemColor,
    );
  }

  @override
  Widget button(
      {Key? key,
      Widget? child,
      void Function()? onPressed,
      void Function()? onLongPressed}) {
    return glassmorphismWidgetFactory.button(
        key: key,
        onPressed: onPressed,
        child: child,
        onLongPressed: onLongPressed);
  }

  @override
  icon(IconData icon,
      {Key? key, double? size, Color? color, double opacity = 0.5}) {
    return glassmorphismWidgetFactory.icon(icon,
        key: key, size: size, color: color, opacity: opacity);
  }

  @override
  Widget listTile(
      {Key? key,
      Widget? leading,
      Widget? title,
      Widget? subtitle,
      Widget? trailing,
      void Function()? onTap}) {
    return glassmorphismWidgetFactory.listTile(
        key: key,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap);
  }

  @override
  Widget text(String data,
      {Key? key,
      TextStyle? style,
      Color color = Colors.white,
      double opacity = 0.5,
      double? fontSize,
      FontWeight fontWeight = FontWeight.bold}) {
    return glassmorphismWidgetFactory.text(data,
        key: key,
        style: style,
        color: color,
        opacity: opacity,
        fontSize: fontSize,
        fontWeight: fontWeight);
  }
}

final GlassKitWidgetFactory glassKitWidgetFactory = GlassKitWidgetFactory();
