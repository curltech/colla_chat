import 'dart:async';
import 'dart:io';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaKitMediaSource {
  static Media? media({required String filename}) {
    Media? media;
    if (filename.startsWith('assets/')) {
      media = Media('asset:///$filename');
    } else if (filename.startsWith('http')) {
      media = Media(filename);
    } else {
      File file = File(filename);
      bool exists = file.existsSync();
      if (exists) {
        media = Media('file:///$filename');
      }
    }

    return media;
  }

  static Playlist fromMediaSource(List<PlatformMediaSource> mediaSources) {
    List<Media> medias = [];
    for (var mediaSource in mediaSources) {
      Media? media_ = media(filename: mediaSource.filename);
      if (media_ != null) {
        medias.add(media_);
      }
    }

    return Playlist(medias);
  }
}

///基于MediaKit实现的媒体播放器
class MediaKitVideoPlayerController extends AbstractMediaPlayerController {
  late final Player player;
  late final VideoController videoController;

  double volume = 1.0;
  double speed = 1.0;

  ValueNotifier<bool> playing = ValueNotifier<bool>(false);

  MediaKitVideoPlayerController() {
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

    MediaKit.ensureInitialized();
    player = Player();
    videoController = VideoController(player);
    player.streams.playlist.listen((e) {});
    player.streams.playing.listen((e) {
      if (e) {
        mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.playing;
        playing.value = true;
      } else {
        mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.stop;
        playing.value = false;
      }
    });
    player.streams.completed.listen((e) {
      if (e) {
        mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.completed;
        playing.value = false;
      }
    });
    player.streams.position.listen((e) {
      mediaPlayerState.position = e;
    });
    player.streams.duration.listen((e) {
      mediaPlayerState.duration = e;
    });
    player.streams.volume.listen((e) {
      volume = e;
    });
    player.streams.rate.listen((e) {
      speed = e;
    });
    player.streams.pitch.listen((e) {});
    player.streams.buffering.listen((e) {});
  }

  @override
  setCurrentIndex(int index) async {
    if (index >= -1 && index < playlist.length && currentIndex != index) {
      close();
      await super.setCurrentIndex(index);
      notifyListeners();
      var currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        Media? media =
            MediaKitMediaSource.media(filename: currentMediaSource.filename);
        if (media != null) {
          player.open(media);
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
    var currentMediaSource = this.currentMediaSource;
    Widget player;
    if (currentMediaSource != null) {
      player = Video(
        controller: videoController,
      );

      Widget playerControlPanel = ValueListenableBuilder(
          valueListenable: playing,
          builder: (BuildContext context, bool playing, Widget? child) {
            return Container(
                alignment: Alignment.center,
                child: IconButton(
                    iconSize: AppIconSize.lgSize,
                    color: Colors.white,
                    onPressed: () {
                      if (playing) {
                        pause();
                      } else {
                        play();
                      }
                    },
                    icon: playing
                        ? const Icon(Icons.pause)
                        : const Icon(Icons.play_arrow)));
          });
      player = Stack(
        children: [
          player,
          playerControlPanel,
        ],
      );
    } else {
      player = Center(
          child: CommonAutoSizeText(
        AppLocalizations.t('Please select a media file'),
        style: const TextStyle(color: Colors.white),
      ));
    }
    return player;
  }

  @override
  close() {
    stop();
    super.setCurrentIndex(-1);
  }

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  play() async {
    await player.play();
  }

  pause() async {
    await player.pause();
  }

  resume() async {
    await player.play();
  }

  stop() async {
    await player.pause();
  }

  seek(Duration position, {int? index}) async {
    await player.seek(position);
  }

  Future<double> getSpeed() async {
    return Future.value(speed);
  }

  setSpeed(double speed) async {
    await player.setRate(speed);
  }

  Future<double> getVolume() async {
    return Future.value(volume);
  }

  setVolume(double volume) async {
    await player.setVolume(volume);
  }
}

final MediaKitVideoPlayerController globalMediaKitVideoPlayerController =
    MediaKitVideoPlayerController();
