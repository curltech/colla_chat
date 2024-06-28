import 'dart:async';
import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
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
  Player? player;
  VideoController? videoController;

  // ValueNotifier<MeeduPlayerController?> meeduPlayerController =
  //     ValueNotifier<MeeduPlayerController?>(null);

  double volume = 1.0;
  double speed = 1.0;

  ValueNotifier<bool> playing = ValueNotifier<bool>(false);
  ValueNotifier<bool> hovering = ValueNotifier<bool>(false);

  MediaKitVideoPlayerController(super.playlistController) {
    MediaKit.ensureInitialized();
    _init();
  }

  _init() {
    if (player == null) {
      player = Player();
      videoController = VideoController(player!);
      player!.stream.playlist.listen((e) {});
      player!.stream.playing.listen((e) {
        if (e) {
          mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.playing;
          playing.value = true;
        } else {
          mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.stop;
          playing.value = false;
        }
      });
      player!.stream.completed.listen((e) {
        if (e) {
          mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.completed;
          playing.value = false;
        }
      });
      player!.stream.position.listen((e) {
        mediaPlayerState.position = e;
      });
      player!.stream.duration.listen((e) {
        mediaPlayerState.duration = e;
      });
      player!.stream.volume.listen((e) {
        volume = e;
      });
      player!.stream.rate.listen((e) {
        speed = e;
      });
      player!.stream.pitch.listen((e) {});
      player!.stream.buffering.listen((e) {});
    }
  }

  @override
  Future<void> playMediaSource(PlatformMediaSource mediaSource) async {
    _init();
    await stop();
    Media? media = MediaKitMediaSource.media(filename: mediaSource.filename);
    if (media != null) {
      player!.open(media);
    }
    filename.value = mediaSource.filename;
  }

  @override
  play() {
    if (player!.state.completed || player!.state.playlist.medias.isEmpty) {
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
          if (filename != null) {
            Widget player = Video(
              controller: videoController!,
              controls: MaterialVideoControls,
            );

            player = MaterialVideoControlsTheme(
              normal: MaterialVideoControlsThemeData(
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 10.0),
                volumeGesture: true,
                brightnessGesture: true,
                seekBarMargin: EdgeInsets.zero,
                seekBarHeight: 2.4,
                seekBarContainerHeight: 36.0,
                seekBarColor: Colors.white,
                seekBarPositionColor: myself.primary,
                seekBarBufferColor: Colors.grey,
                seekBarThumbSize: 15.0,
                seekBarThumbColor: myself.primary,
              ),
              fullscreen: MaterialVideoControlsThemeData(
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 10.0),
                volumeGesture: true,
                brightnessGesture: true,
                seekBarMargin: EdgeInsets.zero,
                seekBarHeight: 2.4,
                seekBarContainerHeight: 36.0,
                seekBarColor: Colors.white,
                seekBarPositionColor: myself.primary,
                seekBarBufferColor: Colors.grey,
                seekBarThumbSize: 15.0,
                seekBarThumbColor: myself.primary,
              ),
              child: player,
            );
            player = Stack(
              children: [
                player,
                buildPlaylistController(),
              ],
            );
            return player;
          } else {
            return Center(
                child: CommonAutoSizeText(
              AppLocalizations.t('Please select a media file'),
              style: const TextStyle(color: Colors.white),
            ));
          }
        });

    return player;
  }

  @override
  dispose() async {
    super.dispose();
    await player?.dispose();
    player = null;
    videoController = null;
  }

  @override
  pause() async {
    await player?.pause();
  }

  @override
  resume() async {
    await player?.play();
  }

  @override
  stop() async {
    await player?.stop();
  }

  seek(Duration position, {int? index}) async {
    await player?.seek(position);
  }

  Future<double> getSpeed() async {
    return Future.value(speed);
  }

  setSpeed(double speed) async {
    await player?.setRate(speed);
  }

  Future<double> getVolume() async {
    return Future.value(volume);
  }

  setVolume(double volume) async {
    await player?.setVolume(volume);
  }
}
