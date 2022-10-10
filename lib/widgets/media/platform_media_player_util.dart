import 'dart:ui' as ui;

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/media_player_slider.dart';
import 'package:colla_chat/widgets/media/platform_media_controller.dart';
import 'package:flutter/material.dart';

class PlatformMediaPlayerUtil {
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
      double? width,
      bool showControls = true}) {
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
          child: controller.buildMediaView(showControls: showControls),
        ),
      );
    });
    return container;
  }

  static Widget buildSliderWidget({
    required BuildContext context,
    required int divisions,
    required double min,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    var sliderThemeData = MediaPlayerSliderUtil.buildSliderTheme(context);
    return SizedBox(
      width: 100.0,
      child: RotatedBox(
          quarterTurns: 0,
          child: SliderTheme(
              data: sliderThemeData,
              child: Slider(
                //divisions: divisions,
                min: min,
                max: max,
                value: value,
                onChanged: onChanged,
              ))),
    );
  }

  ///音量按钮
  static Widget buildVolumeButton(
      BuildContext context, AbstractMediaPlayerController controller) {
    return FutureBuilder<double>(
        future: controller.getVolume(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return buildProgressIndicator();
          }
          return Row(children: [
            Ink(
                child: InkWell(
              child: const Icon(Icons.volume_up, size: 24),
              onTap: () {
                var volumeSlideVisible = controller.volumeSlideVisible;
                controller.volumeSlideVisible = !volumeSlideVisible;
              },
            )),
            Text(snapshot.data!.toStringAsFixed(1)),
            Visibility(
                visible: controller.volumeSlideVisible,
                child: buildSliderWidget(
                  context: context,
                  divisions: 10,
                  min: 0.0,
                  max: 1.0,
                  value: snapshot.data!,
                  onChanged: controller.setVolume,
                )),
          ]);
        });
  }

  ///速度按钮
  static Widget buildSpeedButton(
      BuildContext context, AbstractMediaPlayerController controller) {
    return FutureBuilder<double>(
        future: controller.getSpeed(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return buildProgressIndicator();
          }
          return Row(children: [
            Ink(
                child: InkWell(
              child: const Icon(Icons.speed, size: 24),
              onTap: () {
                var speedSlideVisible = controller.speedSlideVisible;
                controller.speedSlideVisible = !speedSlideVisible;
              },
            )),
            Text(snapshot.data!.toStringAsFixed(1)),
            Visibility(
                visible: controller.speedSlideVisible,
                child: buildSliderWidget(
                  context: context,
                  divisions: 10,
                  min: 0.5,
                  max: 1.5,
                  value: snapshot.data!,
                  onChanged: controller.setSpeed,
                ))
          ]);
        });
  }

  ///简单播放控制面板，包含音量，简单播放按钮，
  static Widget buildSimpleControlPanel(
      BuildContext context, AbstractMediaPlayerController controller) {
    PlayerStatus status = controller.status;
    List<Widget> widgets = [];

    if (status == PlayerStatus.init ||
        status == PlayerStatus.pause ||
        status == PlayerStatus.stop) {
      widgets.add(Ink(
          child: InkWell(
        onTap: controller.play,
        child: const Icon(Icons.play_arrow, size: 36),
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
        // const SizedBox(
        //   width: 25,
        // ),
        buildComplexPlayPanel(context, controller),
        // const SizedBox(
        //   width: 25,
        // ),
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
      child: const Icon(Icons.stop, size: 36),
    )));
    widgets.add(Ink(
        child: InkWell(
      onTap: controller.previous,
      child: const Icon(Icons.skip_previous, size: 36),
    )));
    if (status == PlayerStatus.init ||
        status == PlayerStatus.pause ||
        status == PlayerStatus.stop ||
        status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        onTap: controller.play,
        child: const Icon(Icons.play_arrow, size: 36),
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
        child: const Icon(Icons.replay, size: 24),
        onTap: () => controller.seek(Duration.zero),
      )));
    }
    widgets.add(Ink(
        child: InkWell(
      onTap: controller.next,
      child: const Icon(Icons.skip_next, size: 36),
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
        if (positionData != null) {
          return MediaPlayerSlider(
            duration: positionData.duration,
            position: positionData.position,
            bufferedPosition: positionData.bufferedPosition,
            onChangeEnd: controller.seek,
          );
        } else {
          return buildProgressIndicator();
        }
      },
    );
  }

  static Container buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      width: 24.0,
      height: 24.0,
      child: const CircularProgressIndicator(),
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
    bool showPlaylist = true,
    bool showMediaView = true,
    Color? color,
    double? height,
    double? width,
  }) {
    List<Widget> controls = [];
    var view = Visibility(
      visible: showPlaylist,
      child: buildMediaView(
          controller: controller, color: color, width: width, height: height),
    );
    controls.add(Expanded(child: view));
    if (!showControls) {
      Widget controllerPanel;
      if (simple) {
        controllerPanel = PlatformMediaPlayerUtil.buildSimpleControllerPanel(
            context, controller);
      } else {
        controllerPanel = PlatformMediaPlayerUtil.buildComplexControllerPanel(
            context, controller);
      }
      controls.add(controllerPanel);
    }
    return Stack(children: [
      Column(children: controls),
      Visibility(
          visible: showPlaylist,
          child: PlatformMediaPlayerUtil.buildPlaylist(context, controller))
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
