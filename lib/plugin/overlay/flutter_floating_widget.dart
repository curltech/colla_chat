import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating/floating/manager/floating_manager.dart';
import 'package:flutter_floating/floating/assist/floating_common_params.dart';
import 'package:flutter_floating/floating/assist/floating_edge_type.dart';
import 'package:flutter_floating/floating/assist/fposition.dart';
import 'package:flutter_floating/floating/assist/snap_stop_type.dart';
import 'package:flutter_floating/floating/floating_overlay.dart';
import 'package:get/get.dart';

/// 应用级的悬浮窗控制器
class FlutterFloatingController {
  final Rx<String?> current = Rx<String?>(null);

  String createFloating(
    Widget child, {
    FloatingEdgeType slideType = FloatingEdgeType.onRightAndBottom,
    double? top,
    double? left,
    double? right,
    double? bottom,
    FPosition<double>? position,
    bool enablePositionCache = true,
    bool isShowLog = true,
    bool isSnapToEdge = true,
    bool isStartScroll = true,
    double slideTopHeight = 0,
    double slideBottomHeight = 0,
    bool isDragEnable = true,
    double marginTop = 0,
    double dragOpacity = 0.3,
    double marginBottom = 0,
    double snapToEdgeSpace = 0,
    int snapToEdgeSpeed = 250,
    SnapEdgeType snapEdgeType = SnapEdgeType.snapEdgeAuto,
    int notifyThrottleMs = 16,
  }) {
    String key = UniqueKey().toString();
    var floating = FloatingOverlay(
      child,
      slideType: slideType,
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      params: FloatingParams(
          isShowLog: isShowLog,
          isSnapToEdge: isSnapToEdge,
          enablePositionCache: enablePositionCache,
          dragOpacity: dragOpacity,
          marginTop: marginTop,
          marginBottom: marginBottom,
          snapToEdgeSpace: snapToEdgeSpace,
          snapEdgeType: snapEdgeType,
          notifyThrottleMs: notifyThrottleMs),
    );
    floatingManager.createFloating(key, floating);
    current.value = key;

    return key;
  }

  void show({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    if (floatingManager.containsFloating(key)) {
      FloatingOverlay floating = floatingManager.getFloating(key);

      floating.show();
    }
  }

  bool isShowing({String? key}) {
    key ??= current.value;
    if (key == null) {
      return false;
    }
    if (floatingManager.containsFloating(key)) {
      FloatingOverlay floating = floatingManager.getFloating(key);

      return floating.isShowing;
    }
    return true;
  }

  void hide({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    if (floatingManager.containsFloating(key)) {
      FloatingOverlay floating = floatingManager.getFloating(key);

      floating.hide();
    }
  }

  FloatingOverlay? getFloating({String? key}) {
    key ??= current.value;
    if (key == null) {
      return null;
    }
    if (floatingManager.containsFloating(key)) {
      return floatingManager.getFloating(key);
    }
    return null;
  }

  void open(BuildContext context, {String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    if (floatingManager.containsFloating(key)) {
      FloatingOverlay floating = floatingManager.getFloating(key);

      floating.open(context);
    }
  }

  void close({String? key}) {
    key ??= current.value;
    if (key == null) {
      return;
    }
    if (floatingManager.containsFloating(key)) {
      floatingManager.closeFloating(key);
    }
  }

  void closeAll() {
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
  final Rx<Widget> enabled = Rx<Widget>(nilBox);

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
