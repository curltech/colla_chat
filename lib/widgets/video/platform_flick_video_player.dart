import 'dart:io';

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/audio/platform_audio_player.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flick_video_player/src/utils/web_key_bindings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FlickMediaSource {
  static Future<FlickManager> media({String? filename, Uint8List? data}) async {
    FlickManager flickManager;
    if (filename != null) {
      if (filename.startsWith('assets/')) {
        flickManager = FlickManager(
            videoPlayerController: VideoPlayerController.asset(filename));
      } else if (filename.startsWith('http')) {
        flickManager = FlickManager(
            videoPlayerController: VideoPlayerController.network(filename));
      } else {
        flickManager = FlickManager(
            videoPlayerController: VideoPlayerController.file(File(filename)));
      }
    } else {
      data = data ?? Uint8List.fromList([]);
      filename = await FileUtil.writeTempFile(data, '');
      flickManager = FlickManager(
          videoPlayerController: VideoPlayerController.file(File(filename)));
    }

    return flickManager;
  }

  static Future<List<FlickManager>> playlist(List<String> filenames) async {
    List<FlickManager> flickManagers = [];
    for (var filename in filenames) {
      flickManagers.add(await media(filename: filename));
    }

    return flickManagers;
  }
}

///基于flick实现的媒体播放器和记录器，
class FlickVideoPlayerController extends AbstractMediaPlayerController {
  final List<FlickManager> _flickManagers = [];
  int? _currentIndex;

  FlickVideoPlayerController();

  _open({bool autoStart = false}) {}

  FlickManager? get current {
    if (_currentIndex != null &&
        _currentIndex! >= 0 &&
        _currentIndex! < _flickManagers.length) {
      return _flickManagers[_currentIndex!];
    }
    return null;
  }

  ///基本的视频控制功能
  @override
  play() {
    current?.flickControlManager?.play();
  }

  @override
  seek(Duration position, {int? index}) {
    current?.flickControlManager?.seekTo(position);
  }

  @override
  pause() {
    current?.flickControlManager?.pause();
  }

  @override
  stop() {
    current?.flickControlManager?.pause();
  }

  @override
  setVolume(double volume) {
    current?.flickControlManager?.setVolume(volume);
  }

  @override
  setSpeed(double speed) {
    current?.flickControlManager?.setPlaybackSpeed(speed);
  }

  takeSnapshot(
    String filename,
    int width,
    int height,
  ) {}

  @override
  dispose() {
    super.dispose();
    current!.dispose();
  }

  ///下面是播放列表的功能
  @override
  add({String? filename, Uint8List? data}) async {
    FlickManager flickManager =
        await FlickMediaSource.media(filename: filename, data: data);
    _flickManagers.add(flickManager);
    _currentIndex = _flickManagers.length - 1;
    play();
  }

  @override
  remove(int index) {
    if (index >= 0 && index < _flickManagers.length) {
      FlickManager flickManager = _flickManagers[index];
      flickManager.dispose();
      _flickManagers.removeAt(index);
    }
  }

  @override
  insert(int index, {String? filename, Uint8List? data}) async {
    FlickManager flickManager =
        await FlickMediaSource.media(filename: filename, data: data);
    _flickManagers.insert(index, flickManager);
  }

  @override
  next() {
    _currentIndex = _currentIndex! + 1;
  }

  @override
  previous() {
    _currentIndex = _currentIndex! - 1;
  }

  @override
  setCurrentIndex(int? index) {
    _currentIndex = index;
  }

  @override
  move(int initialIndex, int finalIndex) {
    var flickManager = _flickManagers[initialIndex];
    _flickManagers[initialIndex] = _flickManagers[finalIndex];
    _flickManagers[finalIndex] = flickManager;
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
    required FlickManager flickManager,
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
      flickManager: flickManager,
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
  int? currentIndex() {
    return _currentIndex;
  }

  @override
  Future<Duration?> getBufferedPosition() {
    // TODO: implement getBufferedPosition
    throw UnimplementedError();
  }

  @override
  Future<Duration?> getDuration() {
    // TODO: implement getDuration
    throw UnimplementedError();
  }

  @override
  Future<Duration?> getPosition() {
    // TODO: implement getPosition
    throw UnimplementedError();
  }

  @override
  double getSpeed() {
    // TODO: implement getSpeed
    throw UnimplementedError();
  }

  @override
  double getVolume() {
    // TODO: implement getVolume
    throw UnimplementedError();
  }

  @override
  resume() {
    // TODO: implement resume
    throw UnimplementedError();
  }

  @override
  setShuffleModeEnabled(bool enabled) {
    // TODO: implement setShuffleModeEnabled
    throw UnimplementedError();
  }
}

///采用flick-video-player实现的视频播放器，用于移动设备和web
class PlatformFlickVideoPlayer extends StatefulWidget {
  late final FlickVideoPlayerController controller;

  PlatformFlickVideoPlayer({Key? key, FlickVideoPlayerController? controller})
      : super(key: key) {
    this.controller = controller ?? FlickVideoPlayerController();
  }

  @override
  State createState() => _PlatformFlickVideoPlayerState();
}

class _PlatformFlickVideoPlayerState extends State<PlatformFlickVideoPlayer> {
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
    return VisibilityDetector(
      key: ObjectKey(widget.controller.current),
      onVisibilityChanged: (visiblityInfo) {
        if (visiblityInfo.visibleFraction > 0.9) {
          widget.controller.play();
        }
      },
      child: Container(
        child: FlickVideoPlayer(
          flickManager: widget.controller.current!,
          flickVideoWithControls: FlickVideoWithControls(
            playerLoadingFallback: Positioned.fill(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Container(),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(
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
              flickManager: widget.controller.current,
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
      ),
    );
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
