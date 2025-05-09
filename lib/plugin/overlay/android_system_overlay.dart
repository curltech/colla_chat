import 'dart:isolate';
import 'dart:ui';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// android下的系统级窗口的方法
/// 在main文件里设置overlayMain方法，当调用show方法的时候，便打开其中定义的系统级窗口
class AndroidOverlayWindowUtil {
  /// 检查权限
  static Future<bool> isPermissionGranted() async {
    if (platformParams.android) {
      final bool status = await FlutterOverlayWindow.isPermissionGranted();

      return status;
    }

    return true;
  }

  /// 请求权限，打开权限设置页面
  static Future<bool?> requestPermission() async {
    if (platformParams.android) {
      final bool? status = await FlutterOverlayWindow.requestPermission();

      return status;
    }

    return true;
  }

  /// 打开系统级窗口
  /// - Optional arguments:
  /// `height` the overlay height and default is [overlaySizeFill]
  /// `width` the overlay width and default is [overlaySizeFill]
  /// `OverlayAlignment` the alignment postion on screen and default is [OverlayAlignment.center]
  /// `OverlayFlag` the overlay flag and default is [OverlayFlag.defaultFlag]
  /// `overlayTitle` the notification message and default is "overlay activated"
  /// `overlayContent` the notification message
  /// `enableDrag` to enable/disable dragging the overlay over the screen and default is "false"
  /// `positionGravity` the overlay postion after drag and default is [PositionGravity.none]
  static showOverlay({
    int height = WindowSize.fullCover,
    int width = WindowSize.matchParent,
    OverlayAlignment alignment = OverlayAlignment.center,
    NotificationVisibility visibility = NotificationVisibility.visibilitySecret,
    OverlayFlag flag = OverlayFlag.defaultFlag,
    String overlayTitle = "CollaChat",
    String? overlayContent,
    bool enableDrag = true,
    PositionGravity positionGravity = PositionGravity.auto,
  }) async {
    if (!platformParams.android) {
      return;
    }
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

  /// 关闭系统级窗口
  static closeOverlay() async {
    if (!platformParams.android) {
      return;
    }
    return await FlutterOverlayWindow.closeOverlay();
  }

  /// 主线程和系统窗口线程之间发送数据
  static Future<dynamic> shareData(dynamic data) async {
    if (!platformParams.android) {
      return;
    }
    return await FlutterOverlayWindow.shareData(data);
  }

  /// 主线程和系统窗口线程监听发送来数据
  static listen(
    void Function(dynamic)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) async {
    if (!platformParams.android) {
      return;
    }
    FlutterOverlayWindow.overlayListener.listen(onData,
        onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }

  /// 更新系统窗口的标志，是否接收点击事件
  static updateFlag(OverlayFlag flag) async {
    if (!platformParams.android) {
      return;
    }
    await FlutterOverlayWindow.updateFlag(flag);
  }

  /// 更新系统窗口的大小
  static resizeOverlay(int width, int height) async {
    if (!platformParams.android) {
      return;
    }
    await FlutterOverlayWindow.resizeOverlay(width, height, true);
  }

  static Future<bool> isActive() async {
    if (!platformParams.android) {
      return false;
    }
    return await FlutterOverlayWindow.isActive();
  }

  static disposeOverlayListener() {
    if (!platformParams.android) {
      return;
    }
    FlutterOverlayWindow.disposeOverlayListener();
  }

  static const String portNameOverlay = 'CollaChatOverlay';
  static const String portNameHome = 'CollaChatHome';

  static bool registerPortWithName(SendPort port, String name) {
    if (!platformParams.android) {
      return false;
    }
    return IsolateNameServer.registerPortWithName(port, name);
  }

  static SendPort? lookupPortByName(String name) {
    if (!platformParams.android) {
      return null;
    }
    return IsolateNameServer.lookupPortByName(name);
  }
}

/// 应用在main文件里overlayMain方法定义的系统级窗口
/// 可以接收主窗口的消息并进行显示
class AndroidSystemOverlay extends StatefulWidget {
  const AndroidSystemOverlay({super.key});

  @override
  State<AndroidSystemOverlay> createState() => _AndroidSystemOverlayState();
}

class _AndroidSystemOverlayState extends State<AndroidSystemOverlay> {
  //系统级窗口的形状
  BoxShape currentShape = BoxShape.circle;

  //接收消息的端口
  final receivePort = ReceivePort();

  //主窗口发送消息的端口
  SendPort? homePort;

  //从主窗口接收到的消息
  String? message;

  @override
  void initState() {
    super.initState();
    //注册发送端口
    if (homePort == null) {
      final res = AndroidOverlayWindowUtil.registerPortWithName(
        receivePort.sendPort,
        AndroidOverlayWindowUtil.portNameOverlay,
      );
      logger.i("register send port with name $res");
    }
    //监听主窗口的消息
    receivePort.listen((data) {
      logger.i("message from home: $data");
      setState(() {
        message = 'message from home: $data';
      });
    });
  }

  Future<void> toggleShape() async {
    if (currentShape == BoxShape.rectangle) {
      await AndroidOverlayWindowUtil.resizeOverlay(50, 100);
      setState(() {
        currentShape = BoxShape.circle;
      });
    } else {
      await AndroidOverlayWindowUtil.resizeOverlay(
        WindowSize.matchParent,
        WindowSize.matchParent,
      );
      setState(() {
        currentShape = BoxShape.rectangle;
      });
    }
  }

  Widget _buildShapeButton(BuildContext context) {
    Widget shapeButton = const SizedBox.shrink();
    Widget buttonIcon = AppImage.mdAppImage;
    if (currentShape == BoxShape.rectangle) {
      shapeButton = SizedBox(
        width: 200.0,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.black,
          ),
          onPressed: () {
            AndroidOverlayWindowUtil.closeOverlay();
          },
          child: const Text("Close"),
        ),
      );
      buttonIcon = message == null ? AppImage.mdAppImage : Text(message ?? '');
    }
    return Container(
      height: MediaQuery.sizeOf(context).height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: currentShape,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            shapeButton,
            buttonIcon,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0.0,
      child: GestureDetector(
        onTap: () async {
          await toggleShape();
        },
        child: _buildShapeButton(context),
      ),
    );
  }
}
