import 'dart:isolate';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/plugin/overlay/android_overlay_window_util.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// 应用在main文件里overlayMain方法定义的系统级窗口
/// 可以接收主窗口的消息并进行显示
class ChatMessageOverlay extends StatefulWidget {
  const ChatMessageOverlay({super.key});

  @override
  State<ChatMessageOverlay> createState() => _ChatMessageOverlayState();
}

class _ChatMessageOverlayState extends State<ChatMessageOverlay> {
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
