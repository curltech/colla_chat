import 'package:flutter/material.dart';

import 'glass_widget_factory.dart';
import 'neumorphic/neumorphic_widget_factory.dart';

enum WidgetStyle { glass, neumorphic, fluent }

abstract class WidgetFactory {
  Widget buildContainer({
    Key? key,
    Widget? child,
  });
}

class PlatformWidgetFactory {
  late WidgetFactory widgetFactory;
  WidgetStyle widgetStyle = WidgetStyle.glass;

  PlatformWidgetFactory() {
    switch (widgetStyle) {
      case WidgetStyle.glass:
        widgetFactory = glassWidgetFactory;
        break;
      case WidgetStyle.neumorphic:
        widgetFactory = neumorphicWidgetFactory;
        break;
      default:
        widgetFactory = glassWidgetFactory;
        break;
    }
  }

  Widget buildContainer({
    Key? key,
    Widget? child,
  }) {
    return widgetFactory.buildContainer(key: key, child: child);
  }
}

final platformWidgetFactory = PlatformWidgetFactory();
