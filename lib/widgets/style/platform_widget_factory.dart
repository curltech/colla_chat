import 'package:colla_chat/widgets/style/glass/glass_kit_widget_factory.dart';
import 'package:flutter/material.dart';

import 'package:colla_chat/widgets/style/neumorphic/neumorphic_widget_factory.dart';

enum WidgetStyle { material, glass, neumorphic, fluent }

///不同样式的widget的抽象工厂
abstract class WidgetFactory {
  ///容器
  Widget container({
    Key? key,
    Widget? child,
  });

  ///尺寸容器
  Widget sizedBox({
    Key? key,
    required double width,
    required double height,
    Widget? child,
  });

  ///文本
  Widget text(
    String data, {
    Key? key,
    TextStyle? style,
    Color color = Colors.white,
    double opacity = 0.5,
    double? fontSize,
    FontWeight fontWeight = FontWeight.bold,
  });

  ///标题栏
  PreferredSizeWidget appBar({
    Key? key,
    Widget? leading,
    Widget? title,
    bool? centerTitle,
    List<Widget>? actions,
  });

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
    void Function()? onLongPressed,
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
    TextStyle? style,
    Color color = Colors.white,
    double opacity = 0.5,
    double? fontSize,
    FontWeight fontWeight = FontWeight.bold,
    Key? key,
  }) {
    return widgetFactory.text(data,
        style: style,
        color: color,
        opacity: opacity,
        fontSize: fontSize,
        fontWeight: fontWeight);
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
    void Function()? onLongPressed,
  }) {
    return widgetFactory.button(
        key: key,
        child: child,
        onPressed: onPressed,
        onLongPressed: onLongPressed);
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
