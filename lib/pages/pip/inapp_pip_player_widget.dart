import 'dart:developer';

import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pip_player/models/pip_settings.dart';
import 'package:flutter_pip_player/pip_controller.dart';
import 'package:flutter_pip_player/pip_player.dart';
import 'package:get/get.dart';

/// flutter_pip_player实现的应用内的模拟画中画功能
/// enabled是pip生效的时候显示的组件
class InAppPipPlayerWidget extends StatelessWidget {
  final Rx<Widget> enabled = Rx<Widget>(Container());
  final RxBool isPlaying = false.obs;

  InAppPipPlayerWidget({super.key});

  /// pip显示的组件的配置，包括标题，外框，控制按钮
  final PipController pipController = PipController(
    settings: PipSettings(
      borderRadius: BorderRadius.circular(16),
      backgroundColor: myself.primary,
      progressBarColor: myself.primary,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return PipPlayer(
      controller: pipController,
      content: enabled.value,
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
    );
  }
}

final InAppPipPlayerWidget inAppPipPlayerWidget = InAppPipPlayerWidget();
