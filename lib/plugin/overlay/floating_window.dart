import 'package:flutter/material.dart';
import 'package:flutter_floating/floating/assist/floating_slide_type.dart';
import 'package:flutter_floating/floating/assist/slide_stop_type.dart';
import 'package:flutter_floating/floating/floating.dart';
import 'package:flutter_floating/floating/manager/floating_manager.dart';
import 'package:universal_html/html.dart';

class FloatingWindow {
  /// 创建悬浮窗，然后用open和close方法打开和关闭单悬浮窗
  Floating floating(
    Widget child, {
    FloatingSlideType slideType = FloatingSlideType.onRightAndBottom,
    double? top,
    double? left,
    double? right,
    double? bottom,
    Point<double>? point,
    double moveOpacity = 0.3,
    bool isPosCache = true,
    bool isShowLog = true,
    bool isSnapToEdge = true,
    bool isStartScroll = true,
    double slideTopHeight = 0,
    double slideBottomHeight = 0,
    double snapToEdgeSpace = 0,
    SlideStopType slideStopType = SlideStopType.slideStopAutoType,
  }) {
    return Floating(
      child,
      slideType: slideType,
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      moveOpacity: moveOpacity,
      isPosCache: isPosCache,
      isShowLog: isShowLog,
      isSnapToEdge: isSnapToEdge,
      slideTopHeight: slideTopHeight,
      slideBottomHeight: slideBottomHeight,
      slideStopType: slideStopType,
    );
  }

  /// 创建全局悬浮窗
  Floating createFloating(Object key, Floating floating) {
    return floatingManager.createFloating(key, floating);
  }

  /// 获取全局悬浮窗
  Floating getFloating(Object key) {
    return floatingManager.getFloating(key);
  }

  /// 关闭全局悬浮窗
  closeFloating(Object key) {
    return floatingManager.closeFloating(key);
  }

  /// 关闭所有全局悬浮窗
  closeAllFloating() {
    return floatingManager.closeAllFloating();
  }
}
