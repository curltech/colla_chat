import 'package:colla_chat/widgets/style/platform_widget_factory.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism_widgets/glassmorphism_widgets.dart';

class GlassmorphismWidgetFactory extends WidgetFactory {
  @override
  Widget sizedBox({
    Key? key,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
    double? blur = blur,
    double? width,
    double? height,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    double? radius = 0.0,
    double? border = 0.0,
    BorderRadius? borderRadius = borderRadius,
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
      radius: radius,
      border: border,
      linearGradient: linearGradient ?? defaultLinearGradient,
      borderRadius: borderRadius,
      borderGradient: borderGradient ?? defaultBorderGradient,
      blur: blur,
      constraints: constraints,
      child: child,
    );
  }

  @override
  Widget container({
    Key? key,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
    double? blur = blur,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    double? radius = 0.0,
    double? border = 0.0,
    BorderRadius? borderRadius = borderRadius,
    Widget? child,
  }) {
    return GlassFlexContainer(
      key: key,
      alignment: alignment,
      transform: transform,
      padding: padding,
      margin: margin,
      radius: radius,
      border: border,
      linearGradient: linearGradient ?? defaultLinearGradient,
      borderRadius: borderRadius,
      borderGradient: borderGradient ?? defaultBorderGradient,
      blur: blur,
      constraints: constraints,
      child: child,
    );
  }

  GlassThemeData of(BuildContext context) {
    GlassThemeData data = GlassTheme.of(context);

    return data;
  }

  GlassThemeData themeData({
    double? radius = 0.0,
    double? border = 0.0,
    double? blur = blur,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
    BorderRadius? borderRadius = borderRadius,
  }) {
    GlassThemeData themeData = GlassThemeData(
        radius: radius,
        border: border,
        blur: blur,
        linearGradient: linearGradient ?? defaultLinearGradient,
        borderGradient: borderGradient ?? defaultBorderGradient,
        borderRadius: borderRadius ?? borderRadius);

    return themeData;
  }

  GlassApp app({
    Key? key,
    GlassThemeData? theme,
    required MaterialApp home,
  }) {
    return GlassApp(
      key: key,
      theme: theme,
      home: home,
    );
  }

  @override
  Widget text(
    String data, {
    TextStyle? style,
    Color color = Colors.white,
    double opacity = 0.5,
    double? fontSize,
    FontWeight fontWeight = FontWeight.bold,
    Key? key,
  }) {
    return GlassText(
      data,
      style: style,
      color: color,
      opacity: opacity,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  @override
  PreferredSizeWidget appBar({
    Key? key,
    Widget? leading,
    Widget? title,
    bool? centerTitle,
    double? radius = 0.0,
    double? border = 0.0,
    double? blur = blur,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
    BorderRadius? borderRadius = borderRadius,
    List<Widget>? actions,
  }) {
    return GlassAppBar(
      key: key,
      leading: leading,
      title: title,
      centerTitle: centerTitle,
      radius: radius,
      border: border,
      blur: blur,
      linearGradient: linearGradient ?? primaryLinearGradient,
      borderGradient: borderGradient ?? primaryBorderGradient,
      borderRadius: borderRadius ?? borderRadius,
      actions: actions,
    );
  }

  @override
  Widget listTile({
    Key? key,
    double? radius = 0.0,
    double? border = 0.0,
    double? blur = blur,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
    BorderRadius? borderRadius = borderRadius,
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? trailing,
    void Function()? onTap,
  }) {
    return GlassListTile(
      key: key,
      radius: radius,
      border: border,
      blur: blur,
      linearGradient: linearGradient ?? defaultLinearGradient,
      borderGradient: borderGradient ?? defaultBorderGradient,
      borderRadius: borderRadius,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget button({
    Key? key,
    double? radius = 0.0,
    double? border = 0.0,
    double? blur = blur,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
    BorderRadius? borderRadius = borderRadius,
    Widget? child,
    void Function()? onPressed,
    void Function()? onLongPressed,
  }) {
    return GlassButton(
      key: key,
      radius: radius,
      border: border,
      blur: blur,
      linearGradient: linearGradient ?? defaultLinearGradient,
      borderGradient: borderGradient ?? defaultBorderGradient,
      borderRadius: borderRadius,
      onPressed: onPressed ?? () {},
      onLongPressed: onLongPressed,
      child: child,
    );
  }

  showBottomSheet({
    required BuildContext context,
    Widget? child,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
    double radius = 20,
    double? blur = blur,
    BorderRadius? borderRadius = borderRadius,
  }) {
    showGlassBottomSheet(
        context: context,
        linearGradient: linearGradient ?? defaultLinearGradient,
        borderGradient: borderGradient ?? defaultBorderGradient,
        radius: radius,
        blur: blur,
        borderRadius: borderRadius,
        child: child);
  }

  GlassFloatingActionButton floatingActionButton({
    Key? key,
    required dynamic Function() onPressed,
    Widget? child,
    double? radius = 0.0,
    double? border = 0.0,
    double? blur = blur,
    LinearGradient? linearGradient,
    LinearGradient? borderGradient,
    BorderRadius? borderRadius = borderRadius,
    Object? heroTag,
  }) {
    return GlassFloatingActionButton(
        key: key,
        onPressed: onPressed,
        border: border,
        heroTag: heroTag,
        linearGradient: linearGradient ?? defaultLinearGradient,
        borderGradient: borderGradient ?? defaultBorderGradient,
        radius: radius,
        blur: blur,
        borderRadius: borderRadius,
        child: child);
  }

  GlassBottomBarItem bottomBarItem({
    required Widget icon,
    required Widget title,
    Color? selectedColor,
    Color? unselectedColor,
    LinearGradient? selectedGradient,
    LinearGradient? unselectedGradient,
    double selectedIconColorOpacity = 0.5,
    double unselectedIconColorOpacity = 0.6,
    double? radius = 0.0,
    double? border = 0.0,
    double? blur = blur,
    LinearGradient? selectedBorderGradient,
    LinearGradient? unselectedBorderGradient,
    BorderRadius? borderRadius = borderRadius,
    Widget? activeIcon,
  }) {
    return GlassBottomBarItem(
        icon: icon,
        title: title,
        selectedColor: selectedColor,
        unselectedColor: unselectedColor,
        selectedGradient: selectedGradient,
        unselectedGradient: unselectedGradient,
        selectedIconColorOpacity: selectedIconColorOpacity,
        unselectedIconColorOpacity: unselectedIconColorOpacity,
        radius: radius,
        border: border,
        blur: blur,
        selectedBorderGradient: selectedBorderGradient,
        unselectedBorderGradient: unselectedBorderGradient,
        borderRadius: borderRadius,
        activeIcon: activeIcon);
  }

  @override
  Widget bottomNavigationBar({
    Key? key,
    required List<BottomNavigationBarItem> items,
    int currentIndex = 0,
    dynamic Function(int)? onTap,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    double? selectedColorOpacity,
  }) {
    List<GlassBottomBarItem> glassItems = [];
    for (var item in items) {
      GlassBottomBarItem glassItem = GlassBottomBarItem(
        icon: item.icon,
        title: Text(item.label ?? ''),
      );
      glassItems.add(glassItem);
    }
    return GlassBottomBar(
      key: key,
      items: glassItems,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      selectedColorOpacity: selectedColorOpacity,
      itemShape: const StadiumBorder(),
      margin: const EdgeInsets.all(8),
      itemPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
    );
  }

  @override
  icon(
    IconData icon, {
    Key? key,
    double? size,
    Color? color,
    double opacity = 0.5,
  }) {
    return GlassIcon(
      icon,
      key: key,
      size: size,
      color: color,
      opacity: opacity,
    );
  }
}

final GlassmorphismWidgetFactory glassmorphismWidgetFactory =
    GlassmorphismWidgetFactory();
