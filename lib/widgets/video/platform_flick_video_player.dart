import 'dart:io';

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/media_player_slider.dart';
import 'package:colla_chat/widgets/platform_media_controller.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flick_video_player/src/utils/web_key_bindings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FlickMediaSource {
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

///基于flick实现的媒体播放器和记录器，
class FlickVideoPlayerController extends AbstractMediaPlayerController {
  VideoPlayerController? videoPlayerController;
  FlickManager? _flickManager;

  FlickVideoPlayerController();

  _open({bool autoStart = false}) {}

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

  @override
  setCurrentIndex(int? index) async {
    super.setCurrentIndex(index);
    if (currentMediaSource != null) {
      videoPlayerController =
          await FlickMediaSource.fromMediaSource(currentMediaSource!);
      _flickManager =
          FlickManager(videoPlayerController: videoPlayerController!);
    }
  }

  ///基本的视频控制功能
  @override
  play() {
    if (_flickManager != null) {
      _flickManager!.flickControlManager?.play();
    }
  }

  @override
  seek(Duration position, {int? index}) {
    if (_flickManager != null) {
      _flickManager?.flickControlManager?.seekTo(position);
    }
  }

  @override
  pause() {
    if (_flickManager != null) {
      _flickManager?.flickControlManager?.pause();
    }
  }

  @override
  resume() {
    if (_flickManager != null) {
      _flickManager?.flickControlManager?.play();
    }
  }

  @override
  stop() {
    if (_flickManager != null) {
      _flickManager?.flickControlManager?.pause();
    }
  }

  @override
  Future<Duration?> getBufferedPosition() async {
    if (_flickManager != null) {
      return Future.value(_flickManager
          ?.flickVideoManager?.videoPlayerValue?.buffered[0].start);
    }
    return null;
  }

  @override
  Future<Duration?> getDuration() async {
    if (_flickManager != null) {
      return Future.value(
          _flickManager?.flickVideoManager?.videoPlayerValue?.duration);
    }
    return null;
  }

  @override
  Future<Duration?> getPosition() async {
    if (_flickManager != null) {
      return Future.value(
          _flickManager?.flickVideoManager?.videoPlayerValue?.position);
    }
    return null;
  }

  @override
  Future<double> getSpeed() {
    double speed = 1.0;
    if (_flickManager != null) {
      speed = _flickManager!.flickVideoManager!.videoPlayerValue!.playbackSpeed;
    }
    return Future.value(speed);
  }

  @override
  Future<double> getVolume() {
    double volume = 1.0;
    if (_flickManager != null) {
      volume = _flickManager!.flickVideoManager!.videoPlayerValue!.volume;
    }
    return Future.value(volume);
  }

  @override
  setVolume(double volume) {
    if (_flickManager != null) {
      _flickManager?.flickControlManager?.setVolume(volume);
    }
  }

  @override
  setSpeed(double speed) {
    if (_flickManager != null) {
      _flickManager?.flickControlManager?.setPlaybackSpeed(speed);
    }
  }

  takeSnapshot(
    String filename,
    int width,
    int height,
  ) {}

  @override
  dispose() {
    super.dispose();
    close();
  }

  buildVideoWidget({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    double scale = 1.0,
    bool showControls = true,
    Color? progressBarActiveColor,
    Color? progressBarInactiveColor = Colors.white24,
    Color? progressBarThumbColor,
    Color? progressBarThumbGlowColor = const Color.fromRGBO(0, 161, 214, .2),
    Color? volumeActiveColor,
    Color? volumeInactiveColor = Colors.grey,
    Color volumeBackgroundColor = const Color(0xff424242),
    Color? volumeThumbColor,
    double? progressBarThumbRadius = 10.0,
    double? progressBarThumbGlowRadius = 15.0,
    bool showTimeLeft = false,
    TextStyle progressBarTextStyle = const TextStyle(),
    FilterQuality filterQuality = FilterQuality.low,
    bool showFullscreenButton = false,
    Color fillColor = Colors.black,
  }) {}

  _buildVideoWidget({
    Key? key,
    Widget flickVideoWithControls =
        const FlickVideoWithControls(controls: FlickPortraitControls()),
    Widget? flickVideoWithControlsFullscreen,
    List<SystemUiOverlay> systemUIOverlay = SystemUiOverlay.values,
    List<SystemUiOverlay> systemUIOverlayFullscreen = const [],
    List<DeviceOrientation> preferredDeviceOrientation = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ],
    List<DeviceOrientation> preferredDeviceOrientationFullscreen = const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ],
    bool wakelockEnabled = true,
    bool wakelockEnabledFullscreen = true,
    dynamic Function(html.KeyboardEvent, FlickManager) webKeyDownHandler =
        flickDefaultWebKeyDownHandler,
  }) {
    return FlickVideoPlayer(
      key: key,
      flickManager: _flickManager!,
      flickVideoWithControls: flickVideoWithControls,
      flickVideoWithControlsFullscreen: flickVideoWithControlsFullscreen,
      systemUIOverlay: systemUIOverlay,
      systemUIOverlayFullscreen: systemUIOverlayFullscreen,
      preferredDeviceOrientation: preferredDeviceOrientation,
      preferredDeviceOrientationFullscreen:
          preferredDeviceOrientationFullscreen,
      wakelockEnabled: wakelockEnabled,
      wakelockEnabledFullscreen: wakelockEnabledFullscreen,
      webKeyDownHandler: webKeyDownHandler,
    );
  }

  @override
  setShuffleModeEnabled(bool enabled) {}

  @override
  close() {
    if (_flickManager != null) {
      _flickManager!.dispose();
      videoPlayerController!.dispose();
      videoPlayerController = null;
      _flickManager = null;
    }
  }
}

///采用flick-video-player实现的视频播放器，用于移动设备和web，内部实现采用video_player
class PlatformFlickVideoPlayer extends StatefulWidget {
  late final FlickVideoPlayerController controller;
  final bool simple;
  final bool showControls;

  PlatformFlickVideoPlayer(
      {Key? key,
      FlickVideoPlayerController? controller,
      this.simple = false,
      this.showControls = true})
      : super(key: key) {
    this.controller = controller ?? FlickVideoPlayerController();
  }

  @override
  State createState() => _PlatformFlickVideoPlayerState();
}

class _PlatformFlickVideoPlayerState extends State<PlatformFlickVideoPlayer> {
  bool playlistVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildFlickVideoPlayer(BuildContext context) {
    return VisibilityDetector(
      key: ObjectKey(widget.controller.videoPlayerController),
      onVisibilityChanged: (visiblityInfo) {
        if (visiblityInfo.visibleFraction > 0.9) {
          widget.controller.play();
        }
      },
      child: FlickVideoPlayer(
        flickManager: widget.controller._flickManager!,
        flickVideoWithControls: FlickVideoWithControls(
          playerLoadingFallback: Positioned.fill(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Container(),
                ),
                const Positioned(
                  right: 10,
                  top: 10,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                      strokeWidth: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          controls: FeedPlayerPortraitControls(
            flickMultiManager: widget.controller,
            flickManager: widget.controller._flickManager,
          ),
        ),
        flickVideoWithControlsFullscreen: FlickVideoWithControls(
          playerLoadingFallback: Container(),
          controls: const FlickLandscapeControls(),
          iconThemeData: const IconThemeData(
            size: 40,
            color: Colors.white,
          ),
          textStyle: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
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
          child: _buildFlickVideoPlayer(context),
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
      Widget controllerPanel = PlatformFlickControllerPanel(
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
class PlatformFlickControllerPanel extends StatefulWidget {
  late final FlickVideoPlayerController controller;
  final bool simple;

  PlatformFlickControllerPanel({
    Key? key,
    FlickVideoPlayerController? controller,
    this.simple = false,
  }) : super(key: key) {
    this.controller = controller ?? FlickVideoPlayerController();
  }

  @override
  State createState() => _PlatformFlickControllerPanelState();
}

class _PlatformFlickControllerPanelState
    extends State<PlatformFlickControllerPanel> {
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

class FeedPlayerPortraitControls extends StatelessWidget {
  const FeedPlayerPortraitControls(
      {Key? key, this.flickMultiManager, this.flickManager})
      : super(key: key);

  final FlickVideoPlayerController? flickMultiManager;
  final FlickManager? flickManager;

  @override
  Widget build(BuildContext context) {
    FlickDisplayManager displayManager =
        Provider.of<FlickDisplayManager>(context);
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          FlickAutoHideChild(
            showIfVideoNotInitialized: false,
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const FlickLeftDuration(),
              ),
            ),
          ),
          Expanded(
            child: FlickToggleSoundAction(
              toggleMute: () {
                flickManager?.flickControlManager?.toggleMute();
                displayManager.handleShowPlayerControls();
              },
              child: const FlickSeekVideoAction(
                child: Center(child: FlickVideoBuffer()),
              ),
            ),
          ),
          FlickAutoHideChild(
            autoHide: true,
            showIfVideoNotInitialized: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FlickSoundToggle(
                    toggleMute: () =>
                        flickManager?.flickControlManager?.toggleMute(),
                    color: Colors.white,
                  ),
                ),
                // FlickFullScreenToggle(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
