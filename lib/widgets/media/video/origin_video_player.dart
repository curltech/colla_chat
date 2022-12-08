import 'dart:async';
import 'dart:io';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_control_panel/video_player_control_panel.dart';

class OriginMediaSource {
  static FutureOr<VideoPlayerController> media(
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
      filename = await FileUtil.writeTempFile(data);
      videoPlayerController = VideoPlayerController.file(File(filename!));
    }
    await videoPlayerController.initialize();

    return videoPlayerController;
  }

  static FutureOr<List<VideoPlayerController>> fromMediaSource(
      List<PlatformMediaSource> mediaSources) async {
    List<VideoPlayerController> videoPlayerControllers = [];
    for (var mediaSource in mediaSources) {
      videoPlayerControllers.add(await media(filename: mediaSource.filename));
    }

    return videoPlayerControllers;
  }
}

///基于VideoPlayerControlPanel实现的媒体播放器
class OriginVideoPlayerController extends AbstractMediaPlayerController {
  VideoPlayerController? _controller;

  OriginVideoPlayerController();

  FutureOr<VideoPlayerController?> get controller async {
    if (_controller == null &&
        currentIndex > -1 &&
        currentIndex < playlist.length) {
      PlatformMediaSource mediaSource = playlist[currentIndex];
      _controller =
          await OriginMediaSource.media(filename: mediaSource.filename);
    }
    if (!_controller!.value.isInitialized) {
      logger.e("controller.initialize() failed");
      return null;
    }
    return _controller;
  }

  @override
  previous() async {
    if (currentIndex <= 0) {
      return;
    }
    close();
    super.previous();
    notifyListeners();
    var controller = await this.controller;
    controller?.play();
  }

  @override
  next() async {
    if (currentIndex == -1 || currentIndex >= playlist.length - 1) {
      return;
    }
    close();
    super.next();
    notifyListeners();
    var controller = await this.controller;
    controller?.play();
  }

  Future<VideoPlayerController?> getController() async {
    return await controller;
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    Widget player = FutureBuilder<VideoPlayerController?>(
        future: getController(),
        builder: (BuildContext context,
            AsyncSnapshot<VideoPlayerController?> snapshot) {
          if (snapshot.hasData) {
            VideoPlayerController? controller = snapshot.data;
            if (controller != null) {
              return JkVideoControlPanel(
                key: key,
                controller,
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
          }
          return const Center(child: Text('Please select a media file!'));
        });

    return player;
  }

  @override
  close() {
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  play() async {
    var controller = await this.controller;
    if (controller != null) {
      controller.play();
    }
  }

  pause() async {
    var controller = await this.controller;
    if (controller != null) {
      controller.pause();
    }
  }

  resume() async {
    var controller = await this.controller;
    if (controller != null) {
      controller.play();
    }
  }

  stop() async {
    var controller = await this.controller;
    if (controller != null) {
      controller.pause();
    }
  }

  seek(Duration position, {int? index}) async {
    var controller = await this.controller;
    if (controller != null) {
      controller.seekTo(position);
    }
  }

  Future<double> getSpeed() async {
    double speed = 1.0;
    var controller = await this.controller;
    if (controller != null) {
      speed = controller.value.playbackSpeed;
    }
    return Future.value(speed);
  }

  setSpeed(double speed) async {
    var controller = await this.controller;
    if (controller != null) {
      controller.setPlaybackSpeed(speed);
    }
  }

  Future<double> getVolume() async {
    double volume = 1.0;
    var controller = await this.controller;
    if (controller != null) {
      volume = controller.value.volume;
    }
    return Future.value(volume);
  }

  setVolume(double volume) async {
    var controller = await this.controller;
    if (controller != null) {
      controller.setVolume(volume);
    }
  }

  Future<VideoPlayerValue?> get value async {
    var controller = await this.controller;
    if (controller != null) {
      VideoPlayerValue value = controller.value;

      return value;
    }
    return null;
  }
}
