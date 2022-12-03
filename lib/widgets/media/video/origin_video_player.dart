import 'dart:io';

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

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
      filename = await FileUtil.writeTempFile(data);
      videoPlayerController = VideoPlayerController.file(File(filename!));
    }
    await videoPlayerController.initialize();

    return videoPlayerController;
  }

  static Future<VideoPlayerController> fromMediaSource(
      PlatformMediaSource mediaSource) async {
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

  @override
  Widget buildMediaView({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    double scale = 1.0,
    bool showControls = true,
  }) {
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
