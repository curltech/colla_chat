import 'dart:async';
import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_control_panel/video_player_control_panel.dart';

class OriginMediaSource {
  static Future<VideoPlayerController?> media(
      {required String filename}) async {
    VideoPlayerController? videoPlayerController;
    if (filename.startsWith('assets/')) {
      videoPlayerController = VideoPlayerController.asset(filename);
    } else if (filename.startsWith('http')) {
      videoPlayerController = VideoPlayerController.network(filename);
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
      logger.e("controller.initialize() failed");
      videoPlayerController = null;
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
    fileType = FileType.custom;
    allowedExtensions = [
      'mp3',
      'wav',
      'mp4',
      'm4a',
      'mov',
      'mpeg',
      'aac',
      'rmvb',
      'avi',
      'wmv',
      'mkv',
      'mpg'
    ];
  }

  @override
  setCurrentIndex(int index) async {
    if (index >= -1 && index < playlist.length && currentIndex != index) {
      close();
      await super.setCurrentIndex(index);
      notifyListeners();
      var currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        videoPlayerController.value = await OriginMediaSource.media(
            filename: currentMediaSource.filename);
        if (autoplay && videoPlayerController.value != null) {
          play();
        }
      }
    }
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    // Widget player = VideoPlayer(videoPlayerController!);
    Widget player = ValueListenableBuilder(
        valueListenable: videoPlayerController,
        builder: (BuildContext context,
            VideoPlayerController? videoPlayerController, Widget? child) {
          if (videoPlayerController != null) {
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
              onNextClicked:
                  (currentIndex == -1 || currentIndex >= playlist.length - 1)
                      ? null
                      : () {
                          next();
                        },
              onPlayEnded: next,
            );
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
  close() {
    if (videoPlayerController.value != null) {
      super.setCurrentIndex(-1);
      videoPlayerController.value!.dispose();
      videoPlayerController.value = null;
    }
  }

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  play() async {
    var controller = videoPlayerController.value;
    if (controller != null) {
      controller.play();
    }
  }

  pause() async {
    var controller = videoPlayerController.value;
    if (controller != null) {
      controller.pause();
    }
  }

  resume() async {
    var controller = videoPlayerController.value;
    if (controller != null) {
      controller.play();
    }
  }

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

final OriginVideoPlayerController globalOriginVideoPlayerController =
    OriginVideoPlayerController();
