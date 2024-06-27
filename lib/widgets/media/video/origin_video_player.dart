import 'dart:async';
import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:fl_video/fl_video.dart';
import 'package:flutter/material.dart';
import 'package:video_player_control_panel/video_player_control_panel.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

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

///基于VideoPlayerControlPanel实现的媒体播放器
class OriginVideoPlayerController extends AbstractMediaPlayerController {
  ValueNotifier<VideoPlayerController?> videoPlayerController =
      ValueNotifier<VideoPlayerController?>(null);

  OriginVideoPlayerController() {
    VideoPlayerMediaKit.ensureInitialized(
      android: true,
      iOS: true,
      macOS: true,
      windows: true,
      linux: true,
    );
  }

  @override
  Future<bool> setCurrentIndex(int index) async {
    bool success = false;
    if (index >= -1 && index < playlist.length) {
      success = await super.setCurrentIndex(index);
      if (success) {
        if (videoPlayerController.value != null) {
          await close();
        }
        var currentMediaSource = this.currentMediaSource;
        if (currentMediaSource != null) {
          videoPlayerController.value = await OriginMediaSource.media(
              filename: currentMediaSource.filename);
          if (autoplay && videoPlayerController.value != null) {
            play();
          }
        }
        notifyListeners();
      }
    }
    return success;
  }

  Widget _buildMediaKitVideoPlayer() {
    return AspectRatio(
        aspectRatio: videoPlayerController.value!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            VideoPlayer(videoPlayerController.value!),
            VideoProgressIndicator(videoPlayerController.value!,
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
        FlVideoPlayer(controller: controller),
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
    return JkVideoControlPanel(
      key: key,
      videoPlayerController,
      showClosedCaptionButton: showClosedCaptionButton,
      showFullscreenButton: showFullscreenButton,
      showVolumeButton: showVolumeButton,
      onPrevClicked: (currentIndex <= 0)
          ? null
          : () {
              previous();
            },
      onNextClicked: (currentIndex == -1 || currentIndex >= playlist.length - 1)
          ? null
          : () {
              next();
            },
      onPlayEnded: next,
    );
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    Widget player = ValueListenableBuilder(
        valueListenable: videoPlayerController,
        builder: (BuildContext context,
            VideoPlayerController? videoPlayerController, Widget? child) {
          if (videoPlayerController != null) {
            return _buildMaterialControl(videoPlayerController,
                showClosedCaptionButton: showClosedCaptionButton,
                showFullscreenButton: showFullscreenButton,
                showVolumeButton: showVolumeButton);
          }
          return Center(
              child: CommonAutoSizeText(
            AppLocalizations.t('Please select a media file'),
            style: const TextStyle(color: Colors.white),
          ));
        });

    return player;
  }

  @override
  close() async {
    await super.close();
    if (videoPlayerController.value != null) {
      videoPlayerController.value!.dispose();
      videoPlayerController.value = null;
    }
  }

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  @override
  play() async {
    var controller = videoPlayerController.value;
    if (controller != null) {
      controller.play();
    }
  }

  @override
  pause() async {
    var controller = videoPlayerController.value;
    if (controller != null) {
      controller.pause();
    }
  }

  @override
  resume() async {
    var controller = videoPlayerController.value;
    if (controller != null) {
      controller.play();
    }
  }

  @override
  stop() async {
    var controller = videoPlayerController.value;
    if (controller != null) {
      controller.pause();
    }
  }

  seek(Duration position, {int? index}) async {
    var controller = videoPlayerController.value;
    if (controller != null) {
      controller.seekTo(position);
    }
  }

  Future<double> getSpeed() async {
    double speed = 1.0;
    var controller = videoPlayerController.value;
    if (controller != null) {
      speed = controller.value.playbackSpeed;
    }
    return Future.value(speed);
  }

  setSpeed(double speed) async {
    var controller = videoPlayerController.value;
    if (controller != null) {
      controller.setPlaybackSpeed(speed);
    }
  }

  Future<double> getVolume() async {
    double volume = 1.0;
    var controller = videoPlayerController.value;
    if (controller != null) {
      volume = controller.value.volume;
    }
    return Future.value(volume);
  }

  setVolume(double volume) async {
    var controller = videoPlayerController.value;
    if (controller != null) {
      controller.setVolume(volume);
    }
  }

  VideoPlayerValue? get value {
    var controller = videoPlayerController.value;
    if (controller != null) {
      VideoPlayerValue value = controller.value;

      return value;
    }
    return null;
  }
}
