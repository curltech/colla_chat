import 'dart:io';

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/platform_media_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class VlcMediaSource {
  static Future<VlcPlayerController> media(
      {String? filename, Uint8List? data}) async {
    VlcPlayerController vlcPlayerController;
    if (filename != null) {
      if (filename.startsWith('assets')) {
        vlcPlayerController = VlcPlayerController.asset(filename);
      } else if (filename.startsWith('http')) {
        vlcPlayerController = VlcPlayerController.network(filename);
      } else {
        vlcPlayerController = VlcPlayerController.file(File(filename));
      }
      await vlcPlayerController!.initialize();
    } else {
      data = data ?? Uint8List.fromList([]);
      filename = await FileUtil.writeTempFile(data);
      vlcPlayerController = VlcPlayerController.file(File(filename!));
      await vlcPlayerController.initialize();
    }

    return Future.value(vlcPlayerController);
  }

  static Future<VlcPlayerController> fromMediaSource(
      MediaSource mediaSource) async {
    return await media(filename: mediaSource.filename);
  }
}

///基于flutter vlc实现的媒体播放器和记录器，
class VlcVideoPlayerController extends AbstractMediaPlayerController {
  VlcPlayerController? vlcPlayerController;

  VlcVideoPlayerController() {
    vlcPlayerController = VlcPlayerController.asset('assets/medias/alert.mp3');
  }

  _open({bool autoStart = false}) async {}

  @override
  PlayerStatus get status {
    VlcPlayerValue value = vlcPlayerController!.value;
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
      vlcPlayerController =
          await VlcMediaSource.fromMediaSource(currentMediaSource!);
    }
  }

  ///基本的视频控制功能
  @override
  play() {
    if (vlcPlayerController != null) {
      vlcPlayerController!.play();
    }
  }

  @override
  seek(Duration position, {int? index}) {
    if (vlcPlayerController != null) {
      vlcPlayerController!.seekTo(position);
    }
  }

  @override
  pause() {
    if (vlcPlayerController != null) {
      vlcPlayerController!.pause();
    }
  }

  @override
  resume() {
    if (vlcPlayerController != null) {
      vlcPlayerController!.play();
    }
  }

  @override
  stop() {
    if (vlcPlayerController != null) {
      vlcPlayerController!.pause();
    }
  }

  @override
  Future<Duration?> getBufferedPosition() {
    throw '';
  }

  @override
  Future<Duration?> getDuration() {
    return vlcPlayerController!.getDuration();
  }

  @override
  Future<Duration?> getPosition() {
    return vlcPlayerController!.getPosition();
  }

  @override
  Future<double> getSpeed() async {
    var speed = await vlcPlayerController!.getPlaybackSpeed();
    return speed ?? 1.0;
  }

  @override
  Future<double> getVolume() async {
    var volume = await vlcPlayerController!.getVolume();
    return double.parse('$volume');
  }

  @override
  setVolume(double volume) {
    vlcPlayerController!.setVolume(volume.toInt());
  }

  @override
  setSpeed(double speed) {
    vlcPlayerController!.setPlaybackSpeed(speed);
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
    double aspectRatio = 16 / 9,
    Widget? placeholder,
    bool virtualDisplay = true,
  }) {
    return VlcPlayer(
      key: key,
      controller: vlcPlayerController!,
      aspectRatio: aspectRatio,
      placeholder: placeholder,
      virtualDisplay: virtualDisplay,
    );
  }

  @override
  setShuffleModeEnabled(bool enabled) {}

  @override
  close() {
    if (vlcPlayerController != null) {
      vlcPlayerController!.dispose();
      vlcPlayerController = null;
    }
  }
}
