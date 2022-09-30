import 'dart:ui' as ui;

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/media_player_slider.dart';
import 'package:colla_chat/widgets/media/platform_media_controller.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PlatformMediaPlayer {
  ///显示播放列表按钮
  static Widget buildPlaylistVisibleButton(
      BuildContext context, AbstractMediaPlayerController controller) {
    return Ink(
        child: InkWell(
      child: controller.playlistVisible
          ? const Icon(Icons.visibility_off_rounded, size: 24)
          : const Icon(Icons.visibility_rounded, size: 24),
      onTap: () {
        var playlistVisible = controller.playlistVisible;
        controller.playlistVisible = !playlistVisible;
      },
    ));
  }

  ///播放列表
  static Widget buildPlaylist(
      BuildContext context, AbstractMediaPlayerController controller) {
    List<MediaSource> playlist = controller.playlist;
    return Column(children: [
      Card(
        color: Colors.white.withOpacity(0.5),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16.0, top: 16.0),
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Ink(
                    child: InkWell(
                      child: const Icon(Icons.add),
                      onTap: () async {
                        List<String> filenames = await FileUtil.pickFiles();
                        for (var filename in filenames) {
                          await controller.add(filename: filename);
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 150.0,
              child: ReorderableListView(
                shrinkWrap: true,
                onReorder: (int initialIndex, int finalIndex) async {
                  if (finalIndex > playlist.length) {
                    finalIndex = playlist.length;
                  }
                  if (initialIndex < finalIndex) finalIndex--;
                  controller.move(initialIndex, finalIndex);
                },
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: List.generate(
                  playlist.length,
                  (int index) {
                    return ListTile(
                      key: Key(index.toString()),
                      leading: Text(
                        index.toString(),
                        style: const TextStyle(fontSize: 14.0),
                      ),
                      title: Text(
                        playlist[index].filename.toString(),
                        style: const TextStyle(fontSize: 14.0),
                      ),
                    );
                  },
                  growable: true,
                ),
              ),
            ),
          ],
        ),
      ),
      const Spacer(),
    ]);
  }

  static Widget buildMediaView(
      {required AbstractMediaPlayerController controller,
      Color? color,
      double? height,
      double? width}) {
    color = color ?? Colors.black.withOpacity(1);
    Widget container = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      height = height ?? constraints.maxHeight;
      width = width ?? constraints.maxWidth;
      return Center(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          width: width,
          height: height,
          decoration: BoxDecoration(color: color),
          child: controller.buildMediaView(),
        ),
      );
    });
    return container;
  }

  static void showSliderDialog({
    required BuildContext context,
    required String title,
    required int divisions,
    required double min,
    required double max,
    String suffix = '',
    required double value,
    Stream<dynamic>? stream,
    required ValueChanged<double> onChanged,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: StreamBuilder<dynamic>(
          stream: stream,
          builder: (context, snapshot) {
            var label = '1.0';
            if (snapshot.data != null) {
              var data = snapshot.data;
              // if (data is GeneralState) {
              //   GeneralState generalState = data;
              //   label = '${generalState.volume.toStringAsFixed(1)}$suffix';
              // }
              if (data is double) {
                label = '${data.toStringAsFixed(1)}$suffix';
              }
            }
            return SizedBox(
              height: 100.0,
              child: Column(
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontFamily: 'Fixed',
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0)),
                  RotatedBox(
                      quarterTurns: 0,
                      child: Slider(
                        divisions: divisions,
                        min: min,
                        max: max,
                        value: value,
                        onChanged: onChanged,
                      )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  ///音量按钮
  static Widget buildVolumeButton(
      BuildContext context, AbstractMediaPlayerController controller) {
    return FutureBuilder<double>(
        future: controller.getVolume(),
        builder: (context, snapshot) {
          var label = '1.0';
          if (snapshot.data != null) {
            label = snapshot.data!.toStringAsFixed(1);
          }
          return Ink(
              child: InkWell(
            child: Row(children: [
              const Icon(Icons.volume_up_rounded, size: 24),
              Text(label ?? '')
            ]),
            onTap: () {
              if (snapshot.data != null) {
                showSliderDialog(
                  context: context,
                  title: "Adjust volume",
                  divisions: 10,
                  min: 0.0,
                  max: 1.0,
                  value: snapshot.data!,
                  onChanged: controller.setVolume,
                );
              }
            },
          ));
        });
  }

  ///速度按钮
  static Widget buildSpeedButton(
      BuildContext context, AbstractMediaPlayerController controller) {
    return FutureBuilder<double>(
        future: controller.getVolume(),
        builder: (context, snapshot) {
          var label = '1.0';
          if (snapshot.data != null) {
            label = snapshot.data!.toStringAsFixed(1);
          }
          return Ink(
              child: InkWell(
            child: Row(children: [
              const Icon(Icons.speed_rounded, size: 24),
              Text(label ?? '')
            ]),
            onTap: () {
              if (snapshot.data != null) {
                showSliderDialog(
                  context: context,
                  title: "Adjust speed",
                  divisions: 10,
                  min: 0.5,
                  max: 1.5,
                  value: snapshot.data!,
                  onChanged: controller.setSpeed,
                );
              }
            },
          ));
        });
  }

  ///简单播放控制面板，包含音量，简单播放按钮，
  static Widget buildSimpleControlPanel(
      BuildContext context, AbstractMediaPlayerController controller) {
    PlayerStatus status = controller.status;
    List<Widget> widgets = [];

    if (status == PlayerStatus.init && status == PlayerStatus.stop) {
      widgets.add(Ink(
          child: InkWell(
        onTap: controller.play,
        child: const Icon(Icons.play_arrow_rounded, size: 36),
      )));
    } else if (status == PlayerStatus.playing) {
      widgets.add(Ink(
          child: InkWell(
        onTap: controller.pause,
        child: const Icon(Icons.pause, size: 36),
      )));
    } else if (status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        child: const Icon(Icons.replay, size: 36),
        onTap: () => controller.seek(Duration.zero),
      )));
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildVolumeButton(context, controller),
          Row(children: widgets),
        ]);
  }

  static Widget buildComplexControlPanel(
      BuildContext context, AbstractMediaPlayerController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildVolumeButton(context, controller),
        const SizedBox(
          width: 25,
        ),
        buildComplexPlayPanel(context, controller),
        const SizedBox(
          width: 25,
        ),
        buildSpeedButton(context, controller),
      ],
    );
  }

  ///复杂播放按钮面板
  static Widget buildComplexPlayPanel(
      BuildContext context, AbstractMediaPlayerController controller) {
    PlayerStatus status = controller.status;
    List<Widget> widgets = [];
    widgets.add(Ink(
        child: InkWell(
      onTap: controller.stop,
      child: const Icon(Icons.stop_rounded, size: 36),
    )));
    widgets.add(Ink(
        child: InkWell(
      onTap: controller.previous,
      child: const Icon(Icons.skip_previous_rounded, size: 36),
    )));
    if (status == PlayerStatus.stop || status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        onTap: controller.play,
        child: const Icon(Icons.play_arrow_rounded, size: 36),
      )));
    } else if (status == PlayerStatus.playing) {
      widgets.add(Ink(
          child: InkWell(
        onTap: controller.pause,
        child: const Icon(Icons.pause, size: 36),
      )));
    } else if (status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        child: const Icon(Icons.replay_rounded, size: 24),
        onTap: () => controller.seek(Duration.zero),
      )));
    }
    widgets.add(Ink(
        child: InkWell(
      onTap: controller.next,
      child: const Icon(Icons.skip_next_rounded, size: 36),
    )));
    return Row(
      children: widgets,
    );
  }

  static Future<PositionData> getPositionState(
      BuildContext context, AbstractMediaPlayerController controller) async {
    var duration = await controller.getDuration();
    duration = duration ?? Duration.zero;
    var position = await controller.getPosition();
    position = position ?? Duration.zero;
    return PositionData(position, Duration.zero, duration);
  }

  ///播放进度条
  static Widget buildPlayerSlider(
      BuildContext context, AbstractMediaPlayerController controller) {
    return FutureBuilder<PositionData>(
      future: getPositionState(context, controller),
      builder: (context, snapshot) {
        PositionData? positionData = snapshot.data;
        return MediaPlayerSlider(
          duration: positionData!.duration,
          position: positionData!.position,
          bufferedPosition: positionData.bufferedPosition,
          onChangeEnd: controller.seek,
        );
      },
    );
  }

  ///复杂控制器按钮面板，包含音量，速度和播放按钮
  static Widget buildComplexControllerPanel(
      BuildContext context, AbstractMediaPlayerController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildPlayerSlider(context, controller),
        buildComplexControlPanel(context, controller),
      ],
    );
  }

  ///简单控制器面板，包含简单播放面板和进度条
  static Widget buildSimpleControllerPanel(
      BuildContext context, AbstractMediaPlayerController controller) {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildSimpleControlPanel(context, controller),
        buildPlayerSlider(context, controller),
      ],
    ));
  }

  static Widget buildMediaPlayer(
    BuildContext context,
    AbstractMediaPlayerController controller, {
    bool simple = false,
    bool showControls = true,
    Color? color,
    double? height,
    double? width,
  }) {
    List<Widget> controls = [];
    var view = VisibilityDetector(
      key: ObjectKey(controller),
      onVisibilityChanged: (visiblityInfo) {
        if (visiblityInfo.visibleFraction > 0.9) {
          controller.play();
        }
      },
      child: buildMediaView(
          controller: controller, color: color, width: width, height: height),
    );
    controls.add(Expanded(child: view));
    if (!showControls) {
      Widget controllerPanel;
      if (simple) {
        controllerPanel =
            PlatformMediaPlayer.buildSimpleControllerPanel(context, controller);
      } else {
        controllerPanel = PlatformMediaPlayer.buildComplexControllerPanel(
            context, controller);
      }
      controls.add(controllerPanel);
    }
    return Stack(children: [
      Column(children: controls),
      Visibility(
          visible: controller.playlistVisible,
          child: PlatformMediaPlayer.buildPlaylist(context, controller))
    ]);
  }

  static bool isTablet() {
    bool isTablet = false;
    final double devicePixelRatio = ui.window.devicePixelRatio;
    final double width = ui.window.physicalSize.width;
    final double height = ui.window.physicalSize.height;
    if (devicePixelRatio < 2 && (width >= 1000 || height >= 1000)) {
      isTablet = true;
    } else if (devicePixelRatio == 2 && (width >= 1920 || height >= 1920)) {
      isTablet = true;
    } else {
      isTablet = false;
    }

    return isTablet;
  }

  static bool isPhone() {
    bool isPhone = false;
    final double devicePixelRatio = ui.window.devicePixelRatio;
    final double width = ui.window.physicalSize.width;
    final double height = ui.window.physicalSize.height;
    if (devicePixelRatio < 2 && (width >= 1000 || height >= 1000)) {
      isPhone = false;
    } else if (devicePixelRatio == 2 && (width >= 1920 || height >= 1920)) {
      isPhone = false;
    } else {
      isPhone = true;
    }

    return isPhone;
  }
}
