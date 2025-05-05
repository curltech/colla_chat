import 'dart:developer';

import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pip_player/models/pip_settings.dart';
import 'package:flutter_pip_player/pip_controller.dart';
import 'package:flutter_pip_player/pip_player.dart';
import 'package:get/get.dart';

class InAppPipPlayerWidget extends StatelessWidget with TileDataMixin {
  InAppPipPlayerWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'pip_player';

  @override
  IconData get iconData => Icons.picture_in_picture;

  @override
  String get title => 'In app pip player';

  final RxBool isPlaying = false.obs;

  final PipController pipController = PipController(
    isSnaping: true,
    title: 'Pip player',
    settings: PipSettings(
      collapsedWidth: 200,
      collapsedHeight: 120,
      expandedWidth: 350,
      expandedHeight: 280,
      borderRadius: BorderRadius.circular(16),
      backgroundColor: Colors.indigo,
      progressBarColor: Colors.amber,
      animationDuration: Duration(milliseconds: 400),
      animationCurve: Curves.easeOutQuart,
      isReelsMode: true,
      reelsBackgroundColor: Colors.black45,
      reelsDragSensitivity: 50.0,
      reelsHeight: 100.0,
      reelsSliderColor: Colors.white,
      reelsSliderIcon: Icons.drag_handle,
      reelsSliderIconColor: Colors.black,
      reelsSliderSize: 25,
      reelsWidth: 30,
    ),
  );

  void toggleMiniPlayer() {
    pipController.show();
    pipController.updateSettings(PipSettings(
      collapsedWidth: 150,
      collapsedHeight: 200,
      expandedWidth: 350,
      expandedHeight: 280,
      borderRadius: BorderRadius.circular(16),
      backgroundColor: Colors.indigo,
      progressBarColor: Colors.amber,
      animationDuration: Duration(milliseconds: 400),
      animationCurve: Curves.easeOutQuart,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.play_arrow, size: 30),
          ),
          PipPlayer(
            controller: pipController,
            content: Container(
              color: Colors.amberAccent,
            ),
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
      ),
    );
  }
}
