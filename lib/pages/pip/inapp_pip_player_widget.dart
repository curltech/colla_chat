import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_pip_player/models/pip_settings.dart';
import 'package:flutter_pip_player/pip_controller.dart';
import 'package:flutter_pip_player/pip_player.dart';
import 'package:get/get.dart';

/// flutter_pip_player实现的应用内的模拟画中画功能
/// enabled是pip生效的时候显示的组件
class InAppPipPlayerWidget extends StatelessWidget {
  final Widget disabled;
  final Widget enabled;

  /// 显示的组件的配置，包括标题，外框，控制按钮
  final String title;

  InAppPipPlayerWidget(
      {super.key,
      required this.disabled,
      required this.enabled,
      required this.title});

  final RxBool isPlaying = false.obs;

  /// pip显示的组件的配置，包括标题，外框，控制按钮
  late final PipController pipController = PipController(
    isSnaping: true,
    title: title,
    settings: PipSettings(),
  );

  void show() {
    pipController.show();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        disabled,
        PipPlayer(
          controller: pipController,
          content: enabled,
          onReelsDown: () {
            log('down');
          },
          onReelsUp: () {
            log('up');
          },
          onClose: () {
            pipController.hide();
          },
          onExpand: () {
            pipController.expand();
          },
          onRewind: () {
            pipController.progress - 1;
          },
          onForward: () {
            pipController.progress + 1;
          },
          onFullscreen: () {
            /// Write logic for full screen
            /// you can navigate to other screen
          },
          onPlayPause: () {
            isPlaying.value = !isPlaying.value;
          },
          onTap: () {
            pipController.toggleExpanded();
          },
        ),
      ],
    );
  }
}
