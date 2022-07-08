import 'package:flutter/material.dart';

enum WidgetStyle { glass, neumorphic, fluent }

abstract class GlassWidgetFactory {
  createText() {
    return Text('');
  }
}

abstract class PlatformWidgetFactory {
  createFactory(WidgetStyle widgetStyle) {
    if (widgetStyle == WidgetStyle.glass) {}
  }
}
