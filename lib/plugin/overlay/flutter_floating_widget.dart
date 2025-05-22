import 'package:flutter/material.dart';
import 'package:flutter_floating/floating/assist/Point.dart';
import 'package:flutter_floating/floating/assist/floating_slide_type.dart';
import 'package:flutter_floating/floating/assist/slide_stop_type.dart';
import 'package:flutter_floating/floating/floating.dart';
import 'package:flutter_floating/floating/manager/floating_manager.dart';
import 'package:get/get.dart';

class FlutterFloatingController {
  final FloatingManager floatingManager = FloatingManager();
  final Rx<String?> current = Rx<String?>(null);

  String createFloating(
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
    String key = UniqueKey().toString();
    floatingManager.createFloating(
        key,
        Floating(
          child,
          slideType: slideType,
          top: top,
          left: left,
          right: right,
          bottom: bottom,
          point: point,
          moveOpacity: moveOpacity,
          isPosCache: isPosCache,
          isShowLog: isShowLog,
          isSnapToEdge: isSnapToEdge,
          isStartScroll: isStartScroll,
          slideTopHeight: slideTopHeight,
          slideBottomHeight: slideBottomHeight,
          snapToEdgeSpace: snapToEdgeSpace,
          slideStopType: slideStopType,
        ));
    current.value = key;

    return key;
  }

  open(BuildContext context, {String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    if (floatingManager.containsFloating(key)) {
      Floating floating = floatingManager.getFloating(key);

      floating.open(context);
    }
  }

  showFloating({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    if (floatingManager.containsFloating(key)) {
      Floating floating = floatingManager.getFloating(key);

      floating.showFloating();
    }
  }

  bool isShowing({String? key}) {
    key ??= current.value;
    if (key == null) {
      return false;
    }
    if (floatingManager.containsFloating(key)) {
      Floating floating = floatingManager.getFloating(key);

      return floating.isShowing;
    }
    return true;
  }

  hideFloating({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    if (floatingManager.containsFloating(key)) {
      Floating floating = floatingManager.getFloating(key);

      floating.hideFloating();
    }
  }

  Floating? getFloating({String? key}) {
    key ??= current.value;
    if (key == null) {
      return null;
    }
    if (floatingManager.containsFloating(key)) {
      return floatingManager.getFloating(key);
    }
    return null;
  }

  closeFloating({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    if (floatingManager.containsFloating(key)) {
      floatingManager.closeFloating(key);
    }
  }

  closeAllFloating() {
    floatingManager.closeAllFloating();
  }
}

/// 应用内的悬浮框的主窗口，overlay实现方式
class FlutterFloatingHome extends StatelessWidget {
  final FlutterFloatingController flutterFloatingController =
      FlutterFloatingController();
  final Widget disabled;

  FlutterFloatingHome({super.key, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return disabled;
  }
}

/// 应用级overlay窗口的overlay部分
class FlutterFloatingOverlay extends StatelessWidget {
  final Rx<Widget> enabled = Rx<Widget>(Container());

  //系统级窗口的形状
  final Rx<BoxShape> boxShape = BoxShape.rectangle.obs;

  FlutterFloatingOverlay({super.key});

  Future<void> toggleShape() async {
    if (boxShape.value == BoxShape.rectangle) {
      boxShape.value = BoxShape.circle;
    } else {
      boxShape.value = BoxShape.rectangle;
    }
  }

  Widget _buildEnabledWidget(BuildContext context) {
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          shape: boxShape.value,
        ),
        child: Center(child: enabled.value),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        elevation: 0.0,
        child: _buildEnabledWidget(context));
  }
}

final FlutterFloatingOverlay flutterFloatingOverlay = FlutterFloatingOverlay();
