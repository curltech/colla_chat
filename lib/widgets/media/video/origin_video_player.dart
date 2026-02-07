import 'dart:async';
import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:fl_video/fl_video.dart';
import 'package:flutter/material.dart';
import 'package:video_player_control_panel/video_player_control_panel.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'package:fvp/fvp.dart' as fvp;

class OriginMediaSource {
  static Future<VideoPlayerController?> media(
      {required String filename}) async {
    VideoPlayerController? videoPlayerController;
    if (filename.startsWith('assets/')) {
      videoPlayerController = VideoPlayerController.asset(filename);
    } else if (filename.startsWith('http')) {
      videoPlayerController =
          VideoPlayerController.networkUrl(Uri(path: filename));
    } else {
      File file = File(filename);
      bool exists = file.existsSync();
      if (exists) {
        videoPlayerController = VideoPlayerController.file(file);
      }
    }
    try {
      if (videoPlayerController != null) {
        await videoPlayerController.initialize();
        if (!videoPlayerController.value.isInitialized) {
          logger.e("controller.initialize() failed");
          videoPlayerController = null;
        }
      }
    } catch (e) {
      logger.e("controller.initialize() failed:$e");
      videoPlayerController = null;
      throw 'controller.initialize() failed';
    }

    return videoPlayerController;
  }

  static Future<List<VideoPlayerController>> fromMediaSource(
      List<PlatformMediaSource> mediaSources) async {
    List<VideoPlayerController> videoPlayerControllers = [];
    for (var mediaSource in mediaSources) {
      var videoPlayerController = await media(filename: mediaSource.filename);
      if (videoPlayerController != null) {
        videoPlayerControllers.add(videoPlayerController);
      }
    }

    return videoPlayerControllers;
  }
}

enum BackendType { fvp, mediaKit }

/// 基于VideoPlayer实现的媒体播放器
class OriginVideoPlayerController extends AbstractMediaPlayerController {
  final BackendType? backendType;
  VideoPlayerController? videoPlayerController;

  OriginVideoPlayerController(super.playlistController, {this.backendType}) {
    /// add fvp backend
    if (backendType == BackendType.fvp) {
      fvp.registerWith();
    }

    /// add MediaKit backend
    if (backendType == BackendType.mediaKit) {
      VideoPlayerMediaKit.ensureInitialized(
        android: true,
        iOS: true,
        macOS: true,
        windows: true,
        linux: true,
      );
    }
  }

  @override
  Future<void> playMediaSource(PlatformMediaSource mediaSource) async {
    await close();
    videoPlayerController =
        await OriginMediaSource.media(filename: mediaSource.filename);
    if (autoPlay && videoPlayerController != null) {
      videoPlayerController!.play();
    }
    filename.value = mediaSource.filename;
  }

  @override
  play() {
    if (videoPlayerController == null) {
      if (playlistController.current != null) {
        playMediaSource(playlistController.current!);
      }
    } else {
      if (playlistController.current != null) {
        if (filename.value == playlistController.current!.filename) {
          resume();
        } else {
          playMediaSource(playlistController.current!);
        }
      }
    }
  }

  Widget _buildMediaKitVideoPlayer() {
    return AspectRatio(
        aspectRatio: videoPlayerController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            VideoPlayer(videoPlayerController!),
            VideoProgressIndicator(videoPlayerController!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                    playedColor: myself.primary,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.white)),
          ],
        ));
  }

  Widget _buildCupertinoControl(
    VideoPlayerController videoPlayerController, {
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    FlVideoPlayerController controller = FlVideoPlayerController(
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        looping: true,
        overlay: const IgnorePointer(
            child: Center(
                child: Text('overlay',
                    style: TextStyle(color: Colors.lightBlue, fontSize: 20)))),
        placeholder: const Center(
            child: Text('placeholder',
                style: TextStyle(color: Colors.red, fontSize: 20))),
        controls: CupertinoControls(
            hideDuration: const Duration(seconds: 5),
            enableSpeed: true,
            enableSkip: true,
            enableSubtitle: true,
            enableFullscreen: showFullscreenButton,
            enableVolume: showVolumeButton,
            enablePlay: true,
            enableBottomBar: true,
            onTap: (FlVideoTapEvent event, FlVideoPlayerController controller) {
              debugPrint(event.toString());
            },
            onDragProgress:
                (FlVideoDragProgressEvent event, Duration duration) {
              debugPrint('$event===$duration');
            },
            remainingBuilder: (String position) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
                  child: Text(position,
                      style: const TextStyle(fontSize: 16, color: Colors.red)));
            },
            positionBuilder: (String position) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 0, 6),
                  child: Text(position,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.lightBlue)));
            }));
    return Stack(
      children: [
        FlVideoPlayer(controller: controller),
        buildPlaylistController(),
      ],
    );
  }

  Widget _buildMaterialControl(
    VideoPlayerController videoPlayerController, {
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    bool isInitialized = videoPlayerController.value.isInitialized;
    FlVideoPlayerController controller = FlVideoPlayerController(
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        looping: true,
        placeholder: Center(
            child: Text(AppLocalizations.t('Waiting'),
                style: TextStyle(color: myself.primary, fontSize: 20))),
        controls: MaterialControls(
            progressColors: FlVideoPlayerProgressColors(
                played: myself.primary,
                buffered: Colors.grey,
                background: Colors.white),
            hideDuration: const Duration(seconds: 5),
            enablePlay: true,
            enableFullscreen: showFullscreenButton,
            enableSpeed: true,
            enableVolume: showVolumeButton,
            enableSubtitle: true,
            enablePosition: true,
            enableBottomBar: true,
            onTap:
                (FlVideoTapEvent event, FlVideoPlayerController controller) {},
            onDragProgress:
                (FlVideoDragProgressEvent event, Duration duration) {}));

    return Stack(
      children: [
        FlVideoPlayer(key: key, controller: controller),
        buildPlaylistController(),
      ],
    );
  }

  ///支持windows
  JkVideoControlPanel _buildJkVideoControlPanel(
    VideoPlayerController videoPlayerController, {
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    int? currentIndex = playlistController.currentIndex.value;
    return JkVideoControlPanel(videoPlayerController,
        showClosedCaptionButton: showClosedCaptionButton,
        showFullscreenButton: showFullscreenButton,
        showVolumeButton: showVolumeButton,
        onPrevClicked: (currentIndex == null || currentIndex == 0)
            ? null
            : () {
                playlistController.previous();
                playMediaSource(playlistController.current!);
              },
        onNextClicked: (currentIndex == null ||
                currentIndex >= playlistController.length - 1)
            ? null
            : () {
                playlistController.next();
                playMediaSource(playlistController.current!);
              }, onPlayEnded: () {
      playlistController.next;
      playMediaSource(playlistController.current!);
    });
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    Widget player = ValueListenableBuilder(
        valueListenable: filename,
        builder: (BuildContext context, String? filename, Widget? child) {
          if (videoPlayerController != null) {
            return _buildMaterialControl(videoPlayerController!,
                showClosedCaptionButton: showClosedCaptionButton,
                showFullscreenButton: showFullscreenButton,
                showVolumeButton: showVolumeButton);
          }
          return Center(child: buildOpenFileWidget());
        });

    return player;
  }

  @override
  close() async {
    await super.close();
    if (videoPlayerController != null) {
      videoPlayerController!.dispose();
      videoPlayerController = null;
    }
  }

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  @override
  pause() async {
    videoPlayerController?.pause();
  }

  @override
  resume() async {
    videoPlayerController?.play();
  }

  @override
  stop() async {
    videoPlayerController?.pause();
  }

  Future<void> seek(Duration position, {int? index}) async {
    videoPlayerController?.seekTo(position);
  }

  Future<double> getSpeed() async {
    double speed = 1.0;
    if (videoPlayerController != null) {
      speed = videoPlayerController!.value.playbackSpeed;
    }
    return Future.value(speed);
  }

  Future<void> setSpeed(double speed) async {
    videoPlayerController?.setPlaybackSpeed(speed);
  }

  Future<double> getVolume() async {
    double volume = 1.0;
    if (videoPlayerController != null) {
      volume = videoPlayerController!.value.volume;
    }
    return Future.value(volume);
  }

  Future<void> setVolume(double volume) async {
    videoPlayerController?.setVolume(volume);
  }

  VideoPlayerValue? get value {
    VideoPlayerValue? value = videoPlayerController?.value;

    return value;
  }
}
