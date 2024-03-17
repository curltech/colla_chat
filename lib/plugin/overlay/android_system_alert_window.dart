import 'dart:isolate';
import 'dart:ui';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';

class AndroidSystemAlertWindow {
  appToForeground() {
    // AppToForeground.appToForeground();
  }

  Future<bool?> requestPermissions(
      {SystemWindowPrefMode prefMode = SystemWindowPrefMode.OVERLAY}) async {
    return await SystemAlertWindow.requestPermissions(prefMode: prefMode);
  }

  /// 显示系统窗口
  show({
    SystemWindowGravity gravity = SystemWindowGravity.CENTER,
    int? width,
    int? height,
    String notificationTitle = "Title",
    String notificationBody = "Body",
    SystemWindowPrefMode prefMode = SystemWindowPrefMode.DEFAULT,
    bool isDisableClicks = false,
  }) {
    SystemAlertWindow.showSystemWindow(
        height: height,
        width: width,
        gravity: gravity,
        notificationTitle: AppLocalizations.t(notificationTitle),
        notificationBody: AppLocalizations.t(notificationBody),
        prefMode: prefMode,
        isDisableClicks: isDisableClicks);

    if (platformParams.android) {
      SystemAlertWindow.overlayListener.listen((event) {
        callBack(event);
      });
    }
  }

  /// 更新系统窗口
  update({
    SystemWindowGravity gravity = SystemWindowGravity.CENTER,
    int? width,
    int? height,
    String notificationTitle = "Title",
    String notificationBody = "Body",
    SystemWindowPrefMode prefMode = SystemWindowPrefMode.DEFAULT,
    bool isDisableClicks = false,
  }) {
    SystemAlertWindow.updateSystemWindow(
        width: width,
        height: height,
        gravity: gravity,
        notificationTitle: AppLocalizations.t(notificationTitle),
        notificationBody: AppLocalizations.t(notificationBody),
        prefMode: prefMode,
        isDisableClicks: isDisableClicks);
  }

  close({SystemWindowPrefMode prefMode = SystemWindowPrefMode.OVERLAY}) {
    SystemAlertWindow.closeSystemWindow(prefMode: prefMode);
  }

  remove() {
    SystemAlertWindow.removeOnClickListener();
  }

  static const mainPortName = "foreground_port";

  listen() async {
    ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, mainPortName);
    port.listen((dynamic callBackData) {
      String tag = callBackData[0];
    });
  }

  /// 主线程和系统窗口线程之间发送数据
  Future<dynamic> shareData(dynamic data) async {
    SendPort? port = IsolateNameServer.lookupPortByName(mainPortName);
    port?.send(data);
  }
}

AndroidSystemAlertWindow overlayAppWindow = AndroidSystemAlertWindow();

@pragma('vm:entry-point')
void callBack(String tag) {
  WidgetsFlutterBinding.ensureInitialized();
  print(tag);
  switch (tag) {
    case "simple_button":
    case "updated_simple_button":
      SystemAlertWindow.closeSystemWindow(
          prefMode: SystemWindowPrefMode.OVERLAY);
      break;
    case "focus_button":
      print("Focus button has been called");
      break;
    default:
      print("OnClick event of $tag");
  }
}
