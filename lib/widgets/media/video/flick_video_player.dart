import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flick_video_player/src/utils/web_key_bindings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class FlickMediaSource {
  static Future<FlickManager> media({String? filename, Uint8List? data}) async {
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
      filename = await FileUtil.writeTempFile(data);
      videoPlayerController = VideoPlayerController.file(File(filename!));
    }
    await videoPlayerController.initialize();

    return FlickManager(
      videoPlayerController: videoPlayerController,
      autoPlay: false,
    );
  }

  static Future<List<FlickManager>> fromMediaSource(
      List<PlatformMediaSource> mediaSources) async {
    List<FlickManager> flickManagers = [];
    for (var mediaSource in mediaSources) {
      flickManagers.add(await media(filename: mediaSource.filename));
    }

    return flickManagers;
  }
}

///基于flick实现的媒体播放器和记录器，
class FlickVideoPlayerController extends AbstractMediaPlayerController {
  List<FlickManager> flickManagers = [];

  FlickVideoPlayerController();

  FlickManager? get currentFlickManager {
    if (currentIndex >= 0 && currentIndex < flickManagers.length) {
      return flickManagers[currentIndex];
    }
    return null;
  }

  @override
  PlayerStatus get status {
    if (currentFlickManager != null) {
      var flickVideoManager = currentFlickManager!.flickVideoManager;
      if (flickVideoManager != null) {
        if (flickVideoManager.isPlaying) {
          status = PlayerStatus.playing;
        } else if (flickVideoManager.isBuffering) {
          status = PlayerStatus.buffering;
        } else if (flickVideoManager.isVideoInitialized) {
          status = PlayerStatus.init;
        } else if (flickVideoManager.isVideoEnded) {
          status = PlayerStatus.completed;
        }
      }
    }

    return super.status;
  }

  ///基本的视频控制功能
  @override
  play() {
    if (currentFlickManager != null) {
      currentFlickManager?.flickControlManager?.play();
      status = PlayerStatus.playing;
    }
  }

  @override
  seek(Duration position, {int? index}) {
    if (currentFlickManager != null) {
      currentFlickManager?.flickControlManager?.seekTo(position);
    }
  }

  @override
  pause() {
    if (currentFlickManager != null) {
      currentFlickManager?.flickControlManager?.pause();
      status = PlayerStatus.pause;
    }
  }

  @override
  resume() {
    if (currentFlickManager != null) {
      currentFlickManager?.flickControlManager?.play();
      status = PlayerStatus.playing;
    }
  }

  @override
  stop() {
    if (currentFlickManager != null) {
      currentFlickManager?.flickControlManager?.pause();
      status = PlayerStatus.stop;
    }
  }

  @override
  Future<Duration?> getBufferedPosition() async {
    if (currentFlickManager != null) {
      return Future.value(currentFlickManager
          ?.flickVideoManager?.videoPlayerValue?.buffered[0].start);
    }
    return null;
  }

  @override
  Future<Duration?> getDuration() async {
    if (currentFlickManager != null) {
      return Future.value(
          currentFlickManager?.flickVideoManager?.videoPlayerValue?.duration);
    }
    return null;
  }

  @override
  Future<Duration?> getPosition() async {
    if (currentFlickManager != null) {
      return Future.value(
          currentFlickManager?.flickVideoManager?.videoPlayerValue?.position);
    }
    return null;
  }

  @override
  Future<double> getSpeed() {
    double speed = 1.0;
    if (currentFlickManager != null) {
      speed = currentFlickManager!
          .flickVideoManager!.videoPlayerValue!.playbackSpeed;
    }
    return Future.value(speed);
  }

  @override
  Future<double> getVolume() {
    double volume = 1.0;
    if (currentFlickManager != null) {
      volume = currentFlickManager!.flickVideoManager!.videoPlayerValue!.volume;
    }
    return Future.value(volume);
  }

  @override
  setVolume(double volume) {
    if (currentFlickManager != null) {
      currentFlickManager?.flickControlManager?.setVolume(volume);
    }
  }

  @override
  setSpeed(double speed) {
    if (currentFlickManager != null) {
      currentFlickManager?.flickControlManager?.setPlaybackSpeed(speed);
    }
  }

  ///下面是播放列表的功能
  @override
  Future<PlatformMediaSource?> add({String? filename, List<int>? data}) async {
    PlatformMediaSource? mediaSource =
        await super.add(filename: filename, data: data);
    if (mediaSource != null) {
      FlickManager flickManager =
          await FlickMediaSource.media(filename: mediaSource.filename);
      flickManagers.add(flickManager);
      if (currentIndex == -1) {
        setCurrentIndex(flickManagers.length - 1);
      }
    }

    return mediaSource;
  }

  @override
  remove(int index) {
    super.remove(index);
    if (index >= 0 && index < playlist.length) {
      FlickManager flickManager = flickManagers[index];
      flickManagers.removeAt(index);
      flickManager.dispose();
    }
  }

  @override
  Future<PlatformMediaSource?> insert(int index,
      {String? filename, List<int>? data}) async {
    PlatformMediaSource? mediaSource =
        await super.insert(index, filename: filename, data: data);
    if (mediaSource != null) {
      FlickManager flickManager =
          await FlickMediaSource.media(filename: mediaSource.filename);
      flickManagers.insert(index, flickManager);

      if (currentIndex == -1) {
        setCurrentIndex(index);
      }
    }
    return mediaSource;
  }

  @override
  next() {
    stop();
    super.next();
    play();
  }

  @override
  previous() {
    stop();
    super.previous();
    play();
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

  @override
  Widget buildMediaView({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    double scale = 1.0,
    bool showControls = true,
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
    if (currentFlickManager == null) {
      return const Center(child: Text('Please select a MediaPlayerType!'));
    }
    Widget flickVideoWithControls = FlickVideoWithControls(
        videoFit: fit, controls: const FlickPortraitControls());
    key ??= UniqueKey();
    var flickVideoPlayer = FlickVideoPlayer(
      key: key,
      flickManager: currentFlickManager!,
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
    return flickVideoPlayer;
  }

  @override
  close() {
    for (var flickManager in flickManagers) {
      flickManager.dispose();
    }
    flickManagers = [];
  }
}

///肖像控制器
class FlickPlayerPortraitControls extends StatelessWidget {
  const FlickPlayerPortraitControls(
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
