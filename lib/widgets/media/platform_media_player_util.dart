import 'dart:ui' as ui;

import 'package:colla_chat/widgets/media/media_player_slider.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PlatformMediaPlayerUtil {
  ///显示播放列表按钮
  static Widget buildPlaylistVisibleButton(
      BuildContext context, AbstractMediaPlayerController controller) {
    return Ink(
        child: InkWell(
      child: controller.playlistVisible
          ? const Icon(Icons.playlist_remove, size: 24)
          : const Icon(Icons.playlist_add_check, size: 24),
      onTap: () {
        var playlistVisible = controller.playlistVisible;
        controller.playlistVisible = !playlistVisible;
      },
    ));
  }

  ///播放列表
  static Widget buildPlaylist(
      BuildContext context, AbstractMediaPlayerController controller) {
    List<PlatformMediaSource> playlist = controller.playlist;
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    child: const Icon(Icons.add),
                    onTap: () async {
                      await controller.sourceFilePicker();
                    },
                  ),
                  InkWell(
                    child: const Icon(Icons.remove),
                    onTap: () async {
                      //await controller.remove(index);
                    },
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
      {Key? key,
      required AbstractMediaPlayerController controller,
      Color? color,
      double? height,
      double? width,
      bool showControls = true}) {
    color = color ?? Colors.black.withOpacity(1);
    Widget container = Container(
      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
      width: width,
      height: height,
      decoration: BoxDecoration(color: color),
      child: Center(
        child: controller.buildMediaView(key: key, showControls: showControls),
      ),
    );
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
          double volume = snapshot.data!;
          return Row(children: [
            Ink(
                child: InkWell(
              child: volume == 0.0
                  ? const Icon(Icons.volume_off, size: 24)
                  : const Icon(Icons.volume_up, size: 24),
              onTap: () async {
                // var volumeSlideVisible = controller.volumeSlideVisible;
                // controller.volumeSlideVisible = !volumeSlideVisible;
                var volume = await controller.getVolume();
                if (volume > 0) {
                  controller.setVolume(0);
                } else {
                  controller.setVolume(1);
                }
              },
            )),
            Text(volume.toStringAsFixed(1)),
            Visibility(
                visible: controller.volumeSlideVisible,
                child: buildSliderWidget(
                  context: context,
                  divisions: 10,
                  min: 0.0,
                  max: 1.0,
                  value: volume,
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

  ///播放列表显示，音量，速度和播放按钮
  static Widget buildControlPanel(
    BuildContext context,
    AbstractMediaPlayerController controller, {
    bool showPlaylist = true,
    bool showVolume = true,
    bool showSpeed = false,
    bool showPause = true,
    bool showStop = true,
  }) {
    PlayerStatus status = controller.status;
    List<Widget> rows = [];
    //显示播放列表按钮
    if (showPlaylist) {
      rows.add(PlatformMediaPlayerUtil.buildPlaylistVisibleButton(
          context, controller));
    }
    //播放按钮
    rows.add(buildPlaybackButton(context, controller, status, showPlaylist,
        showPause: showPause, showStop: showStop));

    //音量调整按钮
    if (showVolume) {
      rows.add(PlatformMediaPlayerUtil.buildVolumeButton(context, controller));
    }
    //速度调整按钮
    if (showSpeed) {
      rows.add(PlatformMediaPlayerUtil.buildSpeedButton(context, controller));
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: rows);
  }

  ///播放按钮，停止，上一个，播放，暂停，下一个
  static Widget buildPlaybackButton(
    BuildContext context,
    AbstractMediaPlayerController controller,
    PlayerStatus status,
    bool showPlaylist, {
    bool showPause = true,
    bool showStop = true,
  }) {
    List<Widget> playbacks = [];
    if (showStop) {
      playbacks.add(Ink(
          child: InkWell(
        onTap: controller.stop,
        child: const Icon(Icons.stop, size: 24),
      )));
    }
    if (showPlaylist) {
      playbacks.add(Ink(
          child: InkWell(
        onTap: controller.previous,
        child: const Icon(Icons.skip_previous, size: 24),
      )));
    }
    if (status != PlayerStatus.playing) {
      playbacks.add(Ink(
          child: InkWell(
        onTap: controller.play,
        child: const Icon(Icons.play_arrow, size: 36),
      )));
    } else if (status != PlayerStatus.completed) {
      if (showPause) {
        playbacks.add(Ink(
            child: InkWell(
          onTap: controller.pause,
          child: const Icon(Icons.pause, size: 36),
        )));
      }
    } else {
      playbacks.add(Ink(
          child: InkWell(
        child: const Icon(Icons.replay, size: 36),
        onTap: () => controller.seek(Duration.zero),
      )));
    }
    if (showPlaylist) {
      playbacks.add(Ink(
          child: InkWell(
        onTap: controller.next,
        child: const Icon(Icons.skip_next, size: 24),
      )));
    }
    return Row(
      children: playbacks,
    );
  }

  ///从控制器获取进度数据，getDuration和getPosition
  static Future<PositionData> getPositionState(
      BuildContext context, AbstractMediaPlayerController controller) async {
    var duration = await controller.getDuration();
    duration = duration ?? Duration.zero;
    var position = await controller.getPosition();
    position = position ?? Duration.zero;
    return PositionData(position, Duration.zero, duration);
  }

  ///播放进度指示条
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

  ///定制的复杂控制器按钮面板，包含进度，播放列表显示，音量，速度和播放按钮
  ///显示为两行，第一行为进度指示
  static Widget buildControllerPanel(
    BuildContext context,
    AbstractMediaPlayerController controller, {
    bool showPlaylist = true,
    bool showVolume = true,
    bool showSpeed = false,
    bool showPause = true,
    bool showStop = true,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildPlayerSlider(context, controller),
        buildControlPanel(context, controller,
            showPlaylist: showPlaylist,
            showVolume: showVolume,
            showSpeed: showSpeed,
            showStop: showStop,
            showPause: showPause),
      ],
    );
  }

  /// 构建媒体播放器组件
  static Widget buildMediaPlayer(
    BuildContext context,
    AbstractMediaPlayerController controller, {
    Key? key,
    bool showControls = true,
    bool showPlaylist = true,
    bool showVolume = true,
    bool showSpeed = false,
    bool showPause = true,
    bool showStop = true,
    Color? color,
    double? height,
    double? width,
  }) {
    // 媒体视图，
    Widget mediaView = PlatformMediaPlayerUtil.buildMediaView(
        key: key,
        controller: controller,
        color: color,
        width: width,
        height: height,
        showControls: showControls);
    // 播放列表
    if (showPlaylist) {
      mediaView =
          Visibility(visible: !controller.playlistVisible, child: mediaView);
      Widget playlistWidget = Visibility(
          visible: controller.playlistVisible,
          child: PlatformMediaPlayerUtil.buildPlaylist(context, controller));
      mediaView = Stack(children: [mediaView, playlistWidget]);
    }
    mediaView = VisibilityDetector(
      key: ObjectKey(controller),
      onVisibilityChanged: (visiblityInfo) {
        if (visiblityInfo.visibleFraction == 0) {
          controller.pause();
        } else if (visiblityInfo.visibleFraction > 0.9) {
          controller.play();
        }
      },
      child: mediaView,
    );

    // 定制的媒体控制器
    if (showControls) {
      Widget controllerPanel = buildControllerPanel(
        context,
        controller,
        showVolume: showVolume,
        showSpeed: showSpeed,
        showPause: showPause,
        showStop: showStop,
        showPlaylist: showPlaylist,
      );
      return Column(
          key: key, children: [Expanded(child: mediaView), controllerPanel]);
    }
    return mediaView;
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
