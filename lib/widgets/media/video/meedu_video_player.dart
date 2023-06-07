import 'dart:async';
import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

class MeeduMediaSource {
  static DataSource? media({required String filename}) {
    DataSource? dataSource;
    if (filename.startsWith('assets/')) {
      dataSource = DataSource(type: DataSourceType.asset, source: filename);
    } else if (filename.startsWith('http')) {
      dataSource = DataSource(type: DataSourceType.network, source: filename);
    } else {
      File file = File(filename);
      bool exists = file.existsSync();
      if (exists) {
        dataSource = DataSource(type: DataSourceType.file, file: file);
      }
    }

    return dataSource;
  }

  static List<DataSource> fromMediaSource(
      List<PlatformMediaSource> mediaSources) {
    List<DataSource> dataSources = [];
    for (var mediaSource in mediaSources) {
      var dataSource = media(filename: mediaSource.filename);
      if (dataSource != null) {
        dataSources.add(dataSource);
      }
    }

    return dataSources;
  }
}

///基于VideoPlayerControlPanel实现的媒体播放器
class MeeduVideoPlayerController extends AbstractMediaPlayerController {
  ValueNotifier<MeeduPlayerController?> meeduPlayerController =
      ValueNotifier<MeeduPlayerController?>(null);

  MeeduVideoPlayerController() {
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
    initMeeduPlayer().then((value) {
      meeduPlayerController.value = MeeduPlayerController();
    });
  }

  @override
  setCurrentIndex(int index) async {
    if (index >= -1 && index < playlist.length && currentIndex != index) {
      close();
      await super.setCurrentIndex(index);
      notifyListeners();
      var currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        if (meeduPlayerController.value != null) {
          DataSource? dataSource =
              MeeduMediaSource.media(filename: currentMediaSource.filename);
          meeduPlayerController.value!
              .setDataSource(dataSource!, autoplay: autoplay);
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
        valueListenable: meeduPlayerController,
        builder: (BuildContext context,
            MeeduPlayerController? meeduPlayerController, Widget? child) {
          if (meeduPlayerController != null) {
            return MeeduVideoPlayer(controller: meeduPlayerController);
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
    if (meeduPlayerController.value != null) {
      stop();
      super.setCurrentIndex(-1);
    }
  }

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  play() async {
    var controller = meeduPlayerController.value;
    if (controller != null) {
      controller.play();
    }
  }

  playAsFullscreen(BuildContext context) {
    var controller = meeduPlayerController.value;
    if (controller != null) {
      var currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        DataSource? dataSource =
            MeeduMediaSource.media(filename: currentMediaSource.filename);
        controller.launchAsFullscreen(context,
            autoplay: true, dataSource: dataSource!);
      }
    }
  }

  pause() async {
    var controller = meeduPlayerController.value;
    if (controller != null) {
      controller.pause();
    }
  }

  resume() async {
    var controller = meeduPlayerController.value;
    if (controller != null) {
      controller.play();
    }
  }

  stop() async {
    var controller = meeduPlayerController.value;
    if (controller != null) {
      controller.pause();
    }
  }

  seek(Duration position, {int? index}) async {
    var controller = meeduPlayerController.value;
    if (controller != null) {
      controller.seekTo(position);
    }
  }

  Future<double> getSpeed() async {
    double speed = 1.0;
    var controller = meeduPlayerController.value;
    if (controller != null) {
      speed = controller.playbackSpeed;
    }
    return Future.value(speed);
  }

  setSpeed(double speed) async {
    var controller = meeduPlayerController.value;
    if (controller != null) {
      controller.setPlaybackSpeed(speed);
    }
  }

  Future<double> getVolume() async {
    double volume = 1.0;
    var controller = meeduPlayerController.value;
    if (controller != null) {
      volume = controller.volume.value;
    }
    return Future.value(volume);
  }

  setVolume(double volume) async {
    var controller = meeduPlayerController.value;
    if (controller != null) {
      controller.setVolume(volume);
    }
  }
}

final MeeduVideoPlayerController globalMeeduVideoPlayerController =
    MeeduVideoPlayerController();
