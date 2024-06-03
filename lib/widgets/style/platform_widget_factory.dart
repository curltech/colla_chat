import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/style/glass/glass_kit_widget_factory.dart';
import 'package:flutter/material.dart';

import 'package:colla_chat/widgets/style/neumorphic/neumorphic_widget_factory.dart';
import 'package:flutter/services.dart';

enum WidgetStyle { material, glass, neumorphic, fluent }

/// 不同样式的widget的抽象工厂
abstract class WidgetFactory {
  ///容器
  Widget container({
    Key? key,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    Widget? child,
    Clip clipBehavior = Clip.none,
  }) {
    return Container(
      key: key,
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  ///尺寸容器
  Widget sizedBox({
    Key? key,
    double? width,
    double? height,
    Widget? child,
  }) {
    return SizedBox(
      key: key,
      width: width,
      height: height,
      child: child,
    );
  }

  ///文本
  Widget text(
    String data, {
    Key? key,
    TextAlign? textAlign,
    TextStyle? textStyle,
    bool wrapWords = true,
    TextOverflow? overflow,
    Widget? overflowReplacement,
    double? textScaleFactor,
    int? maxLines,
  }) {
    return CommonAutoSizeText(
      data,
      key: key,
      textAlign: textAlign,
      style: textStyle,
      wrapWords: wrapWords,
      overflow: overflow,
      overflowReplacement: overflowReplacement,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
    );
  }

  ///标题栏
  PreferredSizeWidget appBar({
    Key? key,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Widget? title,
    List<Widget>? actions,
    Widget? flexibleSpace,
    PreferredSizeWidget? bottom,
    double? elevation,
    double? scrolledUnderElevation,
    bool Function(ScrollNotification) notificationPredicate =
        defaultScrollNotificationPredicate,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    Color? backgroundColor,
    Color? foregroundColor,
    IconThemeData? iconTheme,
    IconThemeData? actionsIconTheme,
    bool primary = true,
    bool? centerTitle,
    bool excludeHeaderSemantics = false,
    double? titleSpacing,
    double toolbarOpacity = 1.0,
    double bottomOpacity = 1.0,
    double? toolbarHeight,
    double? leadingWidth,
    TextStyle? toolbarTextStyle,
    TextStyle? titleTextStyle,
    SystemUiOverlayStyle? systemOverlayStyle,
    bool forceMaterialTransparency = false,
    Clip? clipBehavior,
  }) {
    return AppBar(
      key: key,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: title,
      actions: actions,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      notificationPredicate: notificationPredicate,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      shape: shape,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      iconTheme: iconTheme,
      actionsIconTheme: actionsIconTheme,
      primary: primary,
      centerTitle: centerTitle,
      excludeHeaderSemantics: excludeHeaderSemantics,
      titleSpacing: titleSpacing,
      toolbarOpacity: toolbarOpacity,
      bottomOpacity: bottomOpacity,
      toolbarHeight: toolbarHeight,
      leadingWidth: leadingWidth,
      toolbarTextStyle: toolbarTextStyle,
      titleTextStyle: titleTextStyle,
      systemOverlayStyle: systemOverlayStyle,
      forceMaterialTransparency: forceMaterialTransparency,
      clipBehavior: clipBehavior,
    );
  }

  ///列表行
  Widget listTile({
    Key? key,
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? trailing,
    void Function()? onTap,
  });

  ///按钮
  Widget button({
    Key? key,
    Widget? child,
    void Function()? onPressed,
  });

  Widget bottomNavigationBar({
    Key? key,
    required List<BottomNavigationBarItem> items,
    int currentIndex = 0,
    dynamic Function(int)? onTap,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    double? selectedColorOpacity,
  });

  icon(
    IconData icon, {
    Key? key,
    double? size,
    Color? color,
    double opacity = 0.5,
  });
}

///平台使用的widget样式的工厂
class PlatformWidgetFactory {
  WidgetFactory widgetFactory = glassKitWidgetFactory;
  WidgetStyle widgetStyle = WidgetStyle.glass;

  PlatformWidgetFactory() {
    switch (widgetStyle) {
      case WidgetStyle.glass:
        widgetFactory = glassKitWidgetFactory;
        break;
      case WidgetStyle.neumorphic:
        widgetFactory = neumorphicWidgetFactory;
        break;
      default:
        widgetFactory = glassKitWidgetFactory;
        break;
    }
  }

  Widget container({
    Key? key,
    Widget? child,
  }) {
    return widgetFactory.container(key: key, child: child);
  }

  Widget sizedBox({
    Key? key,
    required double width,
    required double height,
    Widget? child,
  }) {
    return widgetFactory.sizedBox(
        key: key, width: width, height: height, child: child);
  }

  Widget text(
    String data, {
    TextAlign? textAlign,
    TextStyle? textStyle,
    Key? key,
  }) {
    return widgetFactory.text(
      data,
      textStyle: textStyle,
      textAlign: textAlign,
    );
  }

  icon(
    IconData icon, {
    Key? key,
    double? size,
    Color? color,
    double opacity = 0.5,
  }) {
    return widgetFactory.icon(icon,
        key: key, size: size, color: color, opacity: opacity);
  }

  ///平台选择的标题栏
  PreferredSizeWidget appBar({
    Key? key,
    Widget? leading,
    Widget? title,
    bool? centerTitle,
    List<Widget>? actions,
  }) {
    return widgetFactory.appBar(
        key: key,
        leading: leading,
        title: title,
        centerTitle: centerTitle,
        actions: actions);
  }

  ///列表行
  Widget listTile({
    Key? key,
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? trailing,
    void Function()? onTap,
  }) {
    return widgetFactory.listTile(
        key: key,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap);
  }

  ///按钮
  Widget button({
    Key? key,
    Widget? child,
    void Function()? onPressed,
  }) {
    return widgetFactory.button(
      key: key,
      child: child,
      onPressed: onPressed,
    );
  }

  Widget bottomNavigationBar({
    Key? key,
    required List<BottomNavigationBarItem> items,
    int currentIndex = 0,
    dynamic Function(int)? onTap,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    double? selectedColorOpacity,
  }) {
    return widgetFactory.bottomNavigationBar(
      key: key,
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      selectedColorOpacity: selectedColorOpacity,
    );
  }
}

final PlatformWidgetFactory platformWidgetFactory = PlatformWidgetFactory();
