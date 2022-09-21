import 'dart:io';

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/video/platform_video_player.dart';
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

///基于flick实现的媒体播放器和记录器，可以截取视频文件的图片作为缩略图
///支持除macos外的平台，linux需要VLC & libVLC installed.
class FlickVideoPlayerController extends AbstractVideoPlayerController {
  final List<FlickManager> _flickManagers = [];
  FlickManager? _activeManager;
  bool _isMute = false;

  FlickVideoPlayerController();

  @override
  open({bool autoStart = false}) {}

  _play() {
    if (_isMute) {
      _activeManager?.flickControlManager?.mute();
    } else {
      _activeManager?.flickControlManager?.unmute();
    }

    _activeManager?.flickControlManager?.play();
  }

  ///基本的视频控制功能
  @override
  play() {
    _activeManager?.flickControlManager?.play();
  }

  @override
  seek(Duration duration) {
    _activeManager?.flickControlManager?.seekTo(duration);
  }

  @override
  pause() {
    _activeManager?.flickControlManager?.pause();
  }

  @override
  playOrPause() {
    _activeManager?.flickControlManager?.togglePlay();
  }

  @override
  stop() {
    _activeManager?.flickControlManager?.pause();
  }

  @override
  setVolume(double volume) {
    _activeManager?.flickControlManager?.setVolume(volume);
  }

  toggleMute() {
    _activeManager?.flickControlManager?.toggleMute();
  }

  @override
  setRate(double rate) {
    _activeManager?.flickControlManager?.setPlaybackSpeed(rate);
  }

  @override
  takeSnapshot(
    String filename,
    int width,
    int height,
  ) {}

  @override
  dispose() {
    _activeManager!.dispose();
  }

  ///下面是播放列表的功能
  @override
  add({String? filename, Uint8List? data}) async {
    FlickManager flickManager =
        await FlickMediaSource.media(filename: filename, data: data);
    _flickManagers.add(flickManager);
    _activeManager = flickManager;
    if (_isMute) {
      flickManager.flickControlManager?.mute();
    } else {
      flickManager.flickControlManager?.unmute();
    }
    if (_flickManagers.length == 1) {
      play();
    }
  }

  @override
  remove(int index) {
    if (index >= 0 && index < _flickManagers.length) {
      FlickManager flickManager = _flickManagers[index];
      if (_activeManager == flickManager) {
        _activeManager = null;
      }
      flickManager.dispose();
      _flickManagers.removeAt(index);
    }
  }

  @override
  insert(int index, {String? filename, Uint8List? data}) async {
    FlickManager flickManager =
        await FlickMediaSource.media(filename: filename, data: data);
    _flickManagers.insert(index, flickManager);
    _activeManager = flickManager;
  }

  @override
  next() {
    int index = _flickManagers.indexOf(_activeManager!);
    _activeManager = _flickManagers[index + 1];
  }

  @override
  previous() {
    int index = _flickManagers.indexOf(_activeManager!);
    _activeManager = _flickManagers[index - 1];
  }

  @override
  jumpToIndex(int index) {
    _activeManager = _flickManagers[index - 1];
  }

  @override
  move(int initialIndex, int finalIndex) {
    var flickManager = _flickManagers[initialIndex];
    _flickManagers[initialIndex] = _flickManagers[finalIndex];
    _flickManagers[finalIndex] = flickManager;
  }

  @override
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
}

///采用flick-video-player实现的视频播放器，用于移动设备和web
class PlatformFlickVideoPlayer extends StatefulWidget {
  late final FlickVideoPlayerController controller;

  PlatformFlickVideoPlayer({Key? key, FlickVideoPlayerController? controller})
      : super(key: key) {
    controller = controller ?? FlickVideoPlayerController();
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
      key: ObjectKey(widget.controller._activeManager),
      onVisibilityChanged: (visiblityInfo) {
        if (visiblityInfo.visibleFraction > 0.9) {
          widget.controller.play();
        }
      },
      child: Container(
        child: FlickVideoPlayer(
          flickManager: widget.controller._activeManager!,
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
              flickManager: widget.controller._activeManager,
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
                flickMultiManager?.toggleMute();
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
                    toggleMute: () => flickMultiManager?.toggleMute(),
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
