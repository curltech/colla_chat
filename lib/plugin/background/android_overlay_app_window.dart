import 'package:colla_chat/constant/base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// android下的系统窗口
class AndroidOverlayWindow {
  /// 启动overlay的界面，必须放在main.dart文件中
  void overlayMain() {
    runApp(const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(child: Text("$appName overlay"))));
  }

  /// 检查权限
  Future<bool> isPermissionGranted() async {
    final bool status = await FlutterOverlayWindow.isPermissionGranted();

    return status;
  }

  /// 请求权限，打开权限设置页面
  Future<bool?> requestPermission() async {
    final bool? status = await FlutterOverlayWindow.requestPermission();

    return status;
  }

  /// 打开系统窗口
  ///
  /// - Optional arguments:
  /// `height` the overlay height and default is [overlaySizeFill]
  /// `width` the overlay width and default is [overlaySizeFill]
  /// `OverlayAlignment` the alignment postion on screen and default is [OverlayAlignment.center]
  /// `OverlayFlag` the overlay flag and default is [OverlayFlag.defaultFlag]
  /// `overlayTitle` the notification message and default is "overlay activated"
  /// `overlayContent` the notification message
  /// `enableDrag` to enable/disable dragging the overlay over the screen and default is "false"
  /// `positionGravity` the overlay postion after drag and default is [PositionGravity.none]
  show({
    int height = WindowSize.fullCover,
    int width = WindowSize.matchParent,
    OverlayAlignment alignment = OverlayAlignment.center,
    NotificationVisibility visibility = NotificationVisibility.visibilitySecret,
    OverlayFlag flag = OverlayFlag.defaultFlag,
    String overlayTitle = "overlay activated",
    String? overlayContent,
    bool enableDrag = false,
    PositionGravity positionGravity = PositionGravity.none,
  }) async {
    return await FlutterOverlayWindow.showOverlay(
        height: height,
        width: width,
        alignment: alignment,
        visibility: visibility,
        flag: flag,
        overlayTitle: overlayTitle,
        overlayContent: overlayContent,
        enableDrag: enableDrag,
        positionGravity: positionGravity);
  }

  /// 关闭系统窗口
  closeOverlay() async {
    return await FlutterOverlayWindow.closeOverlay();
  }

  /// 主线程和系统窗口线程之间发送数据
  Future<dynamic> shareData(dynamic data) async {
    return await FlutterOverlayWindow.shareData(data);
  }

  /// 主线程和系统窗口线程监听发送来数据
  listen(
    void Function(dynamic)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) async {
    FlutterOverlayWindow.overlayListener.listen(onData,
        onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }

  /// 更新系统窗口的标志，是否接收点击事件
  updateFlag(OverlayFlag flag) async {
    await FlutterOverlayWindow.updateFlag(flag);
  }

  /// 更新系统窗口的大小
  resizeOverlay(int width, int height) async {
    await FlutterOverlayWindow.resizeOverlay(width, height);
  }

  Future<bool> isActive() async {
    return await FlutterOverlayWindow.isActive();
  }

  disposeOverlayListener() {
    FlutterOverlayWindow.disposeOverlayListener();
  }
}

final AndroidOverlayWindow androidOverlayWindow = AndroidOverlayWindow();
