import 'dart:isolate';
import 'dart:ui';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/plugin/overlay/overlay_notification.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:system_alert_window/system_alert_window.dart';

/// 系统overlay组件的发送端口的名称
const String mainSendPortName = 'MainSendPortName';

/// 移动版的系统警告窗口的主窗口部分
/// 可以接收overlay组件的消息
class MobileSystemAlertHome extends StatelessWidget {
  final Widget disabled;
  final ReceivePort receivePort = ReceivePort();
  late final SendPort? sendPort;
  final RxBool isShowingWindow = false.obs;
  final Function(dynamic data)? onReceived;

  MobileSystemAlertHome({super.key, required this.disabled, this.onReceived}) {
    _init();
  }

  Future<void> _init() async {
    await SystemAlertWindow.enableLogs(true);
    await SystemAlertWindow.requestPermissions(
        prefMode: SystemWindowPrefMode.OVERLAY);
    final res = IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      mainSendPortName,
    );

    /// 接收系统overlay窗口的消息
    receivePort.listen((data) {
      logger.i("data from OVERLAY: $data");
      if (onReceived != null) {
        onReceived!(data);
      }
    });
    sendPort ??= IsolateNameServer.lookupPortByName(
      mainSendPortName,
    );
  }

  /// 发送消息给系统overlay窗口
  Future<dynamic> sendMessageToOverlay(dynamic data) async {
    return await SystemAlertWindow.sendMessageToOverlay(data);
  }

  /// 更新系统overlay窗口
  Future<bool?> showOverlay({
    SystemWindowGravity gravity = SystemWindowGravity.CENTER,
    int? width,
    int? height,
    String notificationTitle = appName,
    String notificationBody = appName,
    SystemWindowPrefMode prefMode = SystemWindowPrefMode.DEFAULT,
    List<SystemWindowFlags>? layoutParamFlags,
  }) async {
    bool? result;
    if (!isShowingWindow.value) {
      result = await SystemAlertWindow.showSystemWindow(
          height: height,
          width: width,
          notificationTitle: notificationTitle,
          notificationBody: notificationBody,
          gravity: gravity,
          layoutParamFlags: layoutParamFlags,
          prefMode: SystemWindowPrefMode.OVERLAY);
      isShowingWindow.value = true;
    }

    return result;
  }

  /// 更新系统overlay窗口
  Future<bool?> updateOverlayWindow({
    SystemWindowGravity gravity = SystemWindowGravity.CENTER,
    int? width,
    int? height,
    String notificationTitle = appName,
    String notificationBody = appName,
    SystemWindowPrefMode prefMode = SystemWindowPrefMode.DEFAULT,
    List<SystemWindowFlags>? layoutParamFlags,
  }) async {
    return await SystemAlertWindow.updateSystemWindow(
      height: height,
      width: width,
      gravity: gravity,
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
      prefMode: prefMode,
      layoutParamFlags: layoutParamFlags,
      // isDisableClicks: true
    );
  }

  Future<bool?> closeOverlay(
      {SystemWindowPrefMode prefMode = SystemWindowPrefMode.DEFAULT}) async {
    isShowingWindow.value = false;
    return await SystemAlertWindow.closeSystemWindow(prefMode: prefMode);
  }

  @override
  Widget build(BuildContext context) {
    return disabled;
  }
}

/// 移动版的系统警告窗口的overlay部分
/// 支持向主组件发送消息和接收消息
class MobileSystemAlertOverlay extends StatelessWidget {
  final Rx<Widget> enabled = Rx<Widget>(nilBox);
  late final SendPort? sendPort;

  //系统级窗口的形状
  final Rx<BoxShape> boxShape = BoxShape.rectangle.obs;

  MobileSystemAlertOverlay({super.key}) {
    _init();
  }

  void _init() {
    SystemAlertWindow.overlayListener.listen((event) {
      enabled.value = OverlayNotification(
          key: UniqueKey(), description: CommonAutoSizeText(event));
    });
    sendPort = IsolateNameServer.lookupPortByName(
      mainSendPortName,
    );
  }

  /// 发送消息给系统overlay窗口
  void send(Object? message) {
    sendPort ??= IsolateNameServer.lookupPortByName(
      mainSendPortName,
    );
    sendPort?.send(message);
  }

  /// 关闭系统overlay窗口
  Future<bool?> close() async {
    return await SystemAlertWindow.closeSystemWindow(
        prefMode: SystemWindowPrefMode.OVERLAY);
  }

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
