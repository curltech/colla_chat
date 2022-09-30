import 'dart:io';

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/platform_media_controller.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flick_video_player/src/utils/web_key_bindings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:video_player/video_player.dart';

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

  @override
  Widget buildMediaView({
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
    var flickVideoPlayer = FlickVideoPlayer(
      flickManager: _flickManager!,
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
          flickMultiManager: this,
          flickManager: _flickManager,
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
    );
    return flickVideoPlayer;
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
