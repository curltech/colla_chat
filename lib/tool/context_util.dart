import 'package:flutter/material.dart';

class ContextUtil {
  /// 获取组件的基于屏幕的位置
  static Offset? getOffset(GlobalKey key) {
    RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null) {
      return null;
    }
    RenderBox renderBox = renderObject as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);

    return offset;
  }

  /// 获取组件的大小
  static Size? getSize(GlobalKey key) {
    RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null) {
      return null;
    }
    RenderBox renderBox = renderObject as RenderBox;

    return renderBox.size;
  }

  static Size? getContextSize(BuildContext context) {
    return context.size;
  }
}
