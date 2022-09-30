import 'dart:io';

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/media_player_slider.dart';
import 'package:colla_chat/widgets/platform_media_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class OriginMediaSource {
  static Future<VideoPlayerController> media(
      {String? filename, Uint8List? data}) async {
    VideoPlayerController videoPlayerController;
    if (filename != null) {
      if (filename.startsWith('assets/')) {
        videoPlayerController = VideoPlayerController.asset(filename);
      } else if (filename.startsWith('http')) {
        videoPlayerController = VideoPlayerController.network(filename);
      } else {
        videoPlayerController = VideoPlayerController.file(File(filename));
      }
    } else {
      data = data ?? Uint8List.fromList([]);
      filename = await FileUtil.writeTempFile(data, '');
      videoPlayerController = VideoPlayerController.file(File(filename));
    }
    await videoPlayerController.initialize();

    return videoPlayerController;
  }

  static Future<VideoPlayerController> fromMediaSource(
      MediaSource mediaSource) async {
    return await media(filename: mediaSource.filename);
  }
}

///基于原始video_player实现的媒体播放器和记录器，
class OriginVideoPlayerController extends AbstractMediaPlayerController {
  VideoPlayerController? videoPlayerController;

  OriginVideoPlayerController();

  _open({bool autoStart = false}) async {}

  @override
  setCurrentIndex(int? index) async {
    super.setCurrentIndex(index);
    if (currentMediaSource != null) {
      videoPlayerController =
          await OriginMediaSource.fromMediaSource(currentMediaSource!);
    }
  }

  @override
  PlayerStatus get status {
    VideoPlayerValue value = videoPlayerController!.value;
    if (value.isPlaying) {
      return PlayerStatus.playing;
    } else if (value.isBuffering) {
      return PlayerStatus.buffering;
    } else if (value.isInitialized) {
      return PlayerStatus.init;
    }

    return PlayerStatus.stop;
  }

  ///基本的视频控制功能
  @override
  play() {
    if (videoPlayerController != null) {
      videoPlayerController!.play();
    }
  }

  @override
  seek(Duration position, {int? index}) {
    if (videoPlayerController != null) {
      videoPlayerController!.seekTo(position);
    }
  }

  @override
  pause() {
    if (videoPlayerController != null) {
      videoPlayerController!.pause();
    }
  }

  @override
  resume() {
    if (videoPlayerController != null) {
      videoPlayerController!.play();
    }
  }

  @override
  stop() {
    if (videoPlayerController != null) {
      videoPlayerController!.pause();
    }
  }

  @override
  Future<Duration?> getBufferedPosition() {
    VideoPlayerValue value = videoPlayerController!.value;
    return Future.value(value.buffered[0].start);
  }

  @override
  Future<Duration?> getDuration() {
    VideoPlayerValue value = videoPlayerController!.value;
    return Future.value(value.duration);
  }

  @override
  Future<Duration?> getPosition() {
    return videoPlayerController!.position;
  }

  @override
  Future<double> getSpeed() {
    VideoPlayerValue value = videoPlayerController!.value;
    return Future.value(value.playbackSpeed);
  }

  @override
  Future<double> getVolume() {
    VideoPlayerValue value = videoPlayerController!.value;
    return Future.value(value.volume);
  }

  @override
  setVolume(double volume) {
    videoPlayerController!.setVolume(volume);
  }

  @override
  setSpeed(double speed) {
    videoPlayerController!.setPlaybackSpeed(speed);
  }

  Future<Uint8List> takeSnapshot(
    String filename,
    int width,
    int height,
  ) async {
    throw 'Not support';
  }

  @override
  dispose() {
    super.dispose();
    close();
  }

  Widget buildVideoWidget() {
    return VideoPlayer(
      videoPlayerController!,
    );
  }

  @override
  setShuffleModeEnabled(bool enabled) {}

  @override
  close() {
    if (videoPlayerController != null) {
      videoPlayerController!.dispose();
      videoPlayerController = null;
    }
  }
}

///采用Fijk-video-player实现的视频播放器，用于移动设备和web，内部实现采用video_player
class PlatformOriginVideoPlayer extends StatefulWidget {
  late final OriginVideoPlayerController controller;
  final bool simple;
  final bool showControls;

  PlatformOriginVideoPlayer(
      {Key? key,
      OriginVideoPlayerController? controller,
      this.simple = false,
      this.showControls = true})
      : super(key: key) {
    this.controller = controller ?? OriginVideoPlayerController();
  }

  @override
  State createState() => _PlatformOriginVideoPlayerState();
}

class _PlatformOriginVideoPlayerState extends State<PlatformOriginVideoPlayer> {
  bool playlistVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildOriginVideoPlayer(BuildContext context) {
    return VisibilityDetector(
      key: ObjectKey(widget.controller.videoPlayerController),
      onVisibilityChanged: (visiblityInfo) {
        if (visiblityInfo.visibleFraction > 0.9) {
          widget.controller.play();
        }
      },
      child: VideoPlayer(widget.controller.videoPlayerController!),
    );
  }

  Widget _buildVideoView({Color? color, double? height, double? width}) {
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
          child: _buildOriginVideoPlayer(context),
        ),
      );
    });
    return container;
  }

  ///显示播放列表按钮
  Widget _buildPlaylistVisibleButton(BuildContext context) {
    return Ink(
        child: InkWell(
      child: playlistVisible
          ? const Icon(Icons.visibility_off_rounded, size: 24)
          : const Icon(Icons.visibility_rounded, size: 24),
      onTap: () {
        setState(() {
          playlistVisible = !playlistVisible;
        });
      },
    ));
  }

  ///播放列表
  Widget _buildPlaylist(BuildContext context) {
    List<MediaSource> playlist = widget.controller.playlist;
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
                          await widget.controller.add(filename: filename);
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
                  widget.controller.move(initialIndex, finalIndex);
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

  @override
  Widget build(BuildContext context) {
    List<Widget> controls = [];
    controls.add(Expanded(child: _buildVideoView()));
    if (!widget.showControls) {
      Widget controllerPanel = PlatformOriginControllerPanel(
        controller: widget.controller,
        simple: widget.simple,
      );
      controls.add(controllerPanel);
    }
    return Stack(children: [
      Column(children: controls),
      Visibility(visible: playlistVisible, child: _buildPlaylist(context))
    ]);
  }
}

///视频播放器的控制面板
class PlatformOriginControllerPanel extends StatefulWidget {
  late final OriginVideoPlayerController controller;
  final bool simple;

  PlatformOriginControllerPanel({
    Key? key,
    OriginVideoPlayerController? controller,
    this.simple = false,
  }) : super(key: key) {
    this.controller = controller ?? OriginVideoPlayerController();
  }

  @override
  State createState() => _PlatformOriginControllerPanelState();
}

class _PlatformOriginControllerPanelState
    extends State<PlatformOriginControllerPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget controllerPanel;
    if (widget.simple) {
      controllerPanel = _buildSimpleControllerPanel(context);
    } else {
      controllerPanel = _buildComplexControllerPanel(context);
    }
    return controllerPanel;
  }

  ///简单播放控制面板，包含音量，简单播放按钮，
  Row _buildSimpleControlPanel(BuildContext buildContext) {
    PlayerStatus status = widget.controller.status;
    List<Widget> widgets = [];

    if (status == PlayerStatus.init && status == PlayerStatus.stop) {
      widgets.add(Ink(
          child: InkWell(
        onTap: widget.controller.play,
        child: const Icon(Icons.play_arrow_rounded, size: 36),
      )));
    } else if (status == PlayerStatus.playing) {
      widgets.add(Ink(
          child: InkWell(
        onTap: widget.controller.pause,
        child: const Icon(Icons.pause, size: 36),
      )));
    } else if (status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        child: const Icon(Icons.replay, size: 36),
        onTap: () => widget.controller.seek(Duration.zero),
      )));
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVolumeButton(context),
          Row(children: widgets),
        ]);
  }

  ///音量按钮
  Widget _buildVolumeButton(BuildContext context) {
    return FutureBuilder<double>(
        future: widget.controller.getVolume(),
        builder: (context, snapshot) {
          var label = snapshot.data!.toStringAsFixed(1);
          return Ink(
              child: InkWell(
            child: Row(children: [
              const Icon(Icons.volume_up_rounded, size: 24),
              Text(label ?? '')
            ]),
            onTap: () {
              MediaPlayerSliderUtil.showSliderDialog(
                context: context,
                title: "Adjust volume",
                divisions: 10,
                min: 0.0,
                max: 1.0,
                value: snapshot.data!,
                onChanged: widget.controller.setVolume,
              );
            },
          ));
        });
  }

  ///速度按钮
  Widget _buildSpeedButton(BuildContext context) {
    return FutureBuilder<double>(
        future: widget.controller.getVolume(),
        builder: (context, snapshot) {
          var label = snapshot.data!.toStringAsFixed(1);
          return Ink(
              child: InkWell(
            child: Row(children: [
              const Icon(Icons.speed_rounded, size: 24),
              Text(label ?? '')
            ]),
            onTap: () {
              MediaPlayerSliderUtil.showSliderDialog(
                context: context,
                title: "Adjust speed",
                divisions: 10,
                min: 0.5,
                max: 1.5,
                value: snapshot.data!,
                onChanged: widget.controller.setSpeed,
              );
            },
          ));
        });
  }

  Widget _buildComplexControlPanel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVolumeButton(context),
        const SizedBox(
          width: 25,
        ),
        _buildComplexPlayPanel(),
        const SizedBox(
          width: 25,
        ),
        _buildSpeedButton(context),
      ],
    );
  }

  ///复杂播放按钮面板
  Widget _buildComplexPlayPanel() {
    PlayerStatus status = widget.controller.status;
    List<Widget> widgets = [];
    widgets.add(Ink(
        child: InkWell(
      onTap: widget.controller.stop,
      child: const Icon(Icons.stop_rounded, size: 36),
    )));
    widgets.add(Ink(
        child: InkWell(
      onTap: widget.controller.previous,
      child: const Icon(Icons.skip_previous_rounded, size: 36),
    )));
    if (status == PlayerStatus.stop || status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        onTap: widget.controller.play,
        child: const Icon(Icons.play_arrow_rounded, size: 36),
      )));
    } else if (status == PlayerStatus.playing) {
      widgets.add(Ink(
          child: InkWell(
        onTap: widget.controller.pause,
        child: const Icon(Icons.pause, size: 36),
      )));
    } else if (status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        child: const Icon(Icons.replay_rounded, size: 24),
        onTap: () => widget.controller.seek(Duration.zero),
      )));
    }
    widgets.add(Ink(
        child: InkWell(
      onTap: widget.controller.next,
      child: const Icon(Icons.skip_next_rounded, size: 36),
    )));
    return Row(
      children: widgets,
    );
  }

  Future<PositionData> _getPositionState() async {
    var duration = await widget.controller.getDuration();
    duration = duration ?? Duration.zero;
    var position = await widget.controller.getPosition();
    position = position ?? Duration.zero;
    return PositionData(position, Duration.zero, duration);
  }

  ///播放进度条
  Widget _buildPlayerSlider(BuildContext context) {
    return FutureBuilder<PositionData>(
      future: _getPositionState(),
      builder: (context, snapshot) {
        PositionData? positionData = snapshot.data;
        return MediaPlayerSlider(
          duration: positionData!.duration,
          position: positionData!.position,
          bufferedPosition: positionData.bufferedPosition,
          onChangeEnd: widget.controller.seek,
        );
      },
    );
  }

  ///复杂控制器按钮面板，包含音量，速度和播放按钮
  Widget _buildComplexControllerPanel(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPlayerSlider(context),
        _buildComplexControlPanel(context),
      ],
    );
  }

  ///简单控制器面板，包含简单播放面板和进度条
  Widget _buildSimpleControllerPanel(BuildContext context) {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildSimpleControlPanel(context),
        _buildPlayerSlider(context),
      ],
    ));
  }
}
