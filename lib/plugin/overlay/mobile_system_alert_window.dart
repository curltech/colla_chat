import 'dart:isolate';
import 'dart:ui';

import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:system_alert_window/system_alert_window.dart';

class MobileSystemAlertWindowWidget extends StatelessWidget with TileDataMixin {
  MobileSystemAlertWindowWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'mobile_system_alert';

  @override
  IconData get iconData => Icons.picture_in_picture;

  @override
  String get title => 'Mobile system alert window';

  final MobileSystemAlertHome mobileSystemAlertHome =
      MobileSystemAlertHome(disabled: Text('测试版'));

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      withLeading: true,
      title: title,
      rightWidgets: [
        IconButton(
            onPressed: () {
              mobileSystemAlertOverlay.enabled.value =
                  Icon(Icons.access_alarm_outlined);
              mobileSystemAlertHome.showOverlay();
            },
            icon: Icon(Icons.folder_open)),
        IconButton(
            onPressed: () {
              mobileSystemAlertHome.closeOverlayWindow();
            },
            icon: Icon(Icons.folder)),
      ],
      child:
          mobileSystemAlertHome, // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

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
    // await FlutterOverlayWindow.isPermissionGranted();
    // await FlutterOverlayWindow.requestPermission();
    final res = IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      mainSendPortName,
    );
    logger.i("$res: OVERLAY");
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

  Future<dynamic> sendMessageToOverlay(dynamic data) async {
    return await SystemAlertWindow.sendMessageToOverlay(data);
  }

  Future<bool?> showOverlay({
    SystemWindowGravity gravity = SystemWindowGravity.CENTER,
    int? width,
    int? height,
    String notificationTitle = "CollaChat",
    String notificationBody = "CollaChat",
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

  Future<bool?> updateOverlayWindow({
    SystemWindowGravity gravity = SystemWindowGravity.CENTER,
    int? width,
    int? height,
    String notificationTitle = "CollaChat",
    String notificationBody = "CollaChat",
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

  Future<bool?> closeOverlayWindow(
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
  final Rx<Widget> enabled = Rx<Widget>(Container());

  //接收消息的端口
  final receivePort = ReceivePort();
  late final SendPort? sendPort;

  //系统级窗口的形状
  final Rx<BoxShape> boxShape = BoxShape.circle.obs;

  MobileSystemAlertOverlay({super.key}) {
    _init();
  }

  void _init() {
    IsolateNameServer.registerPortWithName(
        receivePort.sendPort, mainSendPortName);
    //监听主窗口的消息
    receivePort.listen((data) {
      logger.i("message from home: $data");
    });
    SystemAlertWindow.overlayListener.listen((event) {
      logger.i("$event in overlay");
    });
    sendPort ??= IsolateNameServer.lookupPortByName(
      mainSendPortName,
    );
  }

  void send(Object? message) {
    sendPort ??= IsolateNameServer.lookupPortByName(
      mainSendPortName,
    );
    sendPort?.send(message);
  }

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: boxShape.value,
      ),
      child: Center(child: enabled.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        elevation: 0.0,
        child: _buildEnabledWidget(context));
  }
}

final MobileSystemAlertOverlay mobileSystemAlertOverlay =
    MobileSystemAlertOverlay();
