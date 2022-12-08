import 'dart:typed_data';

import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

///采用just_audio和record实现的音频的播放和记录，适用于Android, iOS, Linux, macOS, Windows, and web.
class JustAudioSource {
  static Future<AudioSource> audioSource(
      {String? filename,
      Uint8List? data,
      String? id,
      String? album,
      String? title,
      String? artUri}) async {
    AudioSource audioSource;
    id = id ?? await cryptoGraphy.getRandomAsciiString();
    title = title ?? await cryptoGraphy.getRandomAsciiString();
    var tag = MediaItem(
      // Specify a unique ID for each media item:
      id: id,
      // Metadata to display in the notification:
      album: album, //"Album name",
      title: title, //"Song name",
      artUri: artUri != null
          ? Uri.parse(artUri)
          : null, //Uri.parse('https://example.com/albumart.jpg'),
    );
    if (filename != null) {
      if (filename.startsWith('assets')) {
        audioSource = AudioSource.uri(Uri.parse(filename), tag: tag);
      } else if (filename.startsWith('http')) {
        audioSource = AudioSource.uri(Uri.parse(filename), tag: tag);
      } else {
        audioSource = AudioSource.uri(Uri.file(filename), tag: tag);
      }
    } else {
      data = data ?? Uint8List.fromList([]);
      filename = await FileUtil.writeTempFile(data);
      audioSource = AudioSource.uri(Uri.parse(filename!), tag: tag);
    }

    return audioSource;
  }

  static Future<AudioSource> fromMediaSource(PlatformMediaSource mediaSource,
      {String? id, String? album, String? title, String? artUri}) async {
    AudioSource source = await audioSource(
      filename: mediaSource.filename,
      id: id,
      album: album,
      title: title,
      artUri: artUri,
    );

    return source;
  }
}

///JustAudio音频播放器，Android, iOS, Linux, macOS, Windows, and web.
///还可以产生音频播放的波形图形组件
class JustAudioPlayerController extends AbstractMediaPlayerController {
  late AudioPlayer player;

  ///当前版本还不支持windows
  // ConcatenatingAudioSource playlist = ConcatenatingAudioSource(
  //   // Start loading next item just before reaching it
  //   useLazyPreparation: true,
  //   // Customise the shuffle algorithm
  //   shuffleOrder: DefaultShuffleOrder(),
  //   // Specify the playlist items
  //   children: [],
  // );

  JustAudioPlayerController({
    String? userAgent,
    bool handleInterruptions = true,
    bool androidApplyAudioAttributes = true,
    bool handleAudioSessionActivation = true,
    AudioLoadConfiguration? audioLoadConfiguration,
    AudioPipeline? audioPipeline,
    bool androidOffloadSchedulingEnabled = false,
  }) {
    player = AudioPlayer(
        userAgent: userAgent,
        handleInterruptions: handleInterruptions,
        androidApplyAudioAttributes: androidApplyAudioAttributes,
        handleAudioSessionActivation: handleAudioSessionActivation,
        audioLoadConfiguration: audioLoadConfiguration,
        audioPipeline: audioPipeline,
        androidOffloadSchedulingEnabled: androidOffloadSchedulingEnabled);
    player.playerStateStream.listen((state) {
      logger.i('player state:${state.processingState.name}');
    });
  }

  ///设置当前的通用MediaSource，并转换成特定实现的媒体源，并进行设置
  @override
  setCurrentIndex(int? index) async {
    super.setCurrentIndex(index);
    if (currentIndex >= 0 && currentIndex < playlist.length) {
      PlatformMediaSource? currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        AudioSource source =
            await JustAudioSource.fromMediaSource(currentMediaSource);
        var audioSource = player.audioSource;
        if (audioSource != source) {
          try {
            await player.setAudioSource(
              source,
            );
            notifyListeners();
          } catch (e) {
            logger.e('$e');
          }
        }
      }
    }
  }

  play() async {
    var audioSource = player.audioSource;
    if (audioSource != null) {
      await player.play();
    }
  }

  pause() async {
    await player.pause();
  }

  stop() async {
    await player.stop();
  }

  resume() async {
    await player.play();
  }

  @override
  dispose() async {
    await player.dispose();
    super.dispose();
  }

  seek(Duration? position, {int? index}) async {
    if (index != null) {
      setCurrentIndex(index!);
    }
    if (position != null) {
      try {
        await player.seek(position, index: index);
      } catch (e) {
        logger.e('seek failure:$e');
      }
    }
  }

  setLoopMode(LoopMode mode) async {
    await player.setLoopMode(mode);
  }

  Future<Duration?> getDuration() async {
    return player.duration;
  }

  Future<Duration?> getPosition() async {
    return player.position;
  }

  Future<Duration?> getBufferedPosition() async {
    return player.bufferedPosition;
  }

  Future<double> getVolume() async {
    return Future.value(player.volume);
  }

  setVolume(double volume) async {
    await player.setVolume(volume);
  }

  Future<double> getSpeed() async {
    return Future.value(player.speed);
  }

  setSpeed(double speed) async {
    await player.setSpeed(speed);
  }

  /// Collects the data useful for displaying in a seek bar, using a handy
  /// feature of rx_dart to combine the 3 streams of interest into one.
  Stream<PositionData> get positionDataStream {
    return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (position, bufferedPosition, duration) => PositionData(
            position, bufferedPosition, duration ?? Duration.zero));
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    return Container();
  }
}
