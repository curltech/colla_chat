import 'dart:async';
import 'dart:io';

import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class VlcMediaSource {
  static Future<VlcPlayerController?> media({required String filename}) async {
    VlcPlayerController? vlcPlayerController;
    if (filename.startsWith('assets/')) {
      vlcPlayerController = VlcPlayerController.asset(filename);
    } else if (filename.startsWith('http')) {
      vlcPlayerController = VlcPlayerController.network(filename);
    } else {
      File file = File(filename);
      bool exists = file.existsSync();
      if (exists) {
        vlcPlayerController = VlcPlayerController.file(file);
      }
    }
    try {
      if (vlcPlayerController != null) {
        await vlcPlayerController.initialize();
        if (!vlcPlayerController.value.isInitialized) {
          logger.e("controller.initialize() failed");
          vlcPlayerController = null;
        }
      }
    } catch (e) {
      logger.e("controller.initialize() failed:$e");
      vlcPlayerController = null;
      throw 'controller.initialize() failed';
    }

    return vlcPlayerController;
  }

  static Future<List<VlcPlayerController>> fromMediaSource(
      List<PlatformMediaSource> mediaSources) async {
    List<VlcPlayerController> vlcPlayerControllers = [];
    for (var mediaSource in mediaSources) {
      var vlcPlayerController = await media(filename: mediaSource.filename);
      if (vlcPlayerController != null) {
        vlcPlayerControllers.add(vlcPlayerController);
      }
    }

    return vlcPlayerControllers;
  }
}

///基于Vlc实现的媒体播放器
class MobileVlcPlayerController extends AbstractMediaPlayerController {
  VlcPlayerController? vlcPlayerController;

  MobileVlcPlayerController(super.playlistController);

  @override
  Future<void> playMediaSource(PlatformMediaSource mediaSource) async {
    await close();
    vlcPlayerController =
        await VlcMediaSource.media(filename: mediaSource.filename);
    if (autoPlay && vlcPlayerController != null) {
      vlcPlayerController!.play();
    }
    filename.value = mediaSource.filename;
  }

  @override
  play() {
    if (vlcPlayerController == null) {
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
          if (vlcPlayerController != null) {
            return VlcPlayer(
              controller: vlcPlayerController!,
              aspectRatio: 16 / 9,
              placeholder: Center(child: CircularProgressIndicator()),
            );
          }
          return Center(child: buildOpenFileWidget());
        });

    return player;
  }

  @override
  close() async {
    await super.close();
    if (vlcPlayerController != null) {
      vlcPlayerController!.dispose();
      vlcPlayerController = null;
    }
  }

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  @override
  pause() async {
    vlcPlayerController?.pause();
  }

  @override
  resume() async {
    vlcPlayerController?.play();
  }

  @override
  stop() async {
    vlcPlayerController?.stop();
  }

  Future<void> seek(Duration position, {int? index}) async {
    vlcPlayerController?.seekTo(position);
  }

  Future<double> getSpeed() async {
    double speed = 1.0;
    if (vlcPlayerController != null) {
      speed = vlcPlayerController!.value.playbackSpeed;
    }
    return Future.value(speed);
  }

  Future<void> setSpeed(double speed) async {
    vlcPlayerController?.setPlaybackSpeed(speed);
  }

  Future<double> getVolume() async {
    double volume = 1.0;
    if (vlcPlayerController != null) {
      volume = vlcPlayerController!.value.volume.toDouble();
    }
    return Future.value(volume);
  }

  Future<void> setVolume(double volume) async {
    vlcPlayerController?.setVolume(volume.toInt());
  }

  VlcPlayerValue? get value {
    VlcPlayerValue? value = vlcPlayerController?.value;

    return value;
  }
}
