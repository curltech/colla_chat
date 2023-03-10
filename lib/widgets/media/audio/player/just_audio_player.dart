import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/abstract_audio_player_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

class JustAudioPlayer {
  late AudioPlayer player;

  JustAudioPlayer({
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
  }

  AudioSource _audioSource({required String filename}) {
    AudioSource audioSource;
    if (filename.startsWith('assets')) {
      audioSource = AudioSource.uri(Uri.parse(filename));
    } else if (filename.startsWith('http')) {
      audioSource = AudioSource.uri(Uri.parse(filename));
    } else {
      audioSource = AudioSource.uri(Uri.file(filename));
    }

    return audioSource;
  }

  play(String filename) async {
    try {
      AudioSource audioSource = _audioSource(filename: filename);
      await player.setAudioSource(audioSource);
      await player.play();
    } catch (e) {
      logger.e('$e');
    }
  }

  pause() async {
    await player.pause();
  }

  resume() async {
    await player.play();
  }

  stop() async {
    await player.stop();
  }

  release() async {
    await player.dispose();
  }

  setLoopMode(bool mode) async {
    await player.setLoopMode(mode ? LoopMode.all : LoopMode.off);
  }
}

///采用just_audio和record实现的音频的播放和记录，适用于Android, iOS, Linux, macOS, Windows, and web.
class JustAudioSource {
  static AudioSource audioSource(
      {required String filename,
      String? id,
      String? album,
      String? title,
      String? artUri}) {
    AudioSource audioSource;
    id = id ?? '';
    title = title ?? '';
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
    if (filename.startsWith('assets')) {
      audioSource = AudioSource.uri(Uri.parse(filename), tag: tag);
    } else if (filename.startsWith('http')) {
      audioSource = AudioSource.uri(Uri.parse(filename), tag: tag);
    } else {
      audioSource = AudioSource.uri(Uri.file(filename), tag: tag);
    }

    return audioSource;
  }

  static AudioSource fromMediaSource(PlatformMediaSource mediaSource,
      {String? id, String? album, String? title, String? artUri}) {
    AudioSource source = audioSource(
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
class JustAudioPlayerController extends AbstractAudioPlayerController {
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
    player.bufferedPositionStream.listen((duration) {
      logger.i('player state:$duration');
    });
    player.androidAudioSessionIdStream.listen((duration) {
      logger.i('player state:$duration');
    });
    player.createPositionStream().listen((duration) {
      logger.i('player state:$duration');
    });
    player.currentIndexStream.listen((duration) {
      logger.i('player state:$duration');
    });
    player.durationStream.listen((duration) {
      logger.i('player state:$duration');
    });
    player.playbackEventStream.listen((duration) {
      logger.i('player state:$duration');
    });
    player.processingStateStream.listen((duration) {
      logger.i('player state:$duration');
    });
  }

  ///设置当前的通用MediaSource，并转换成特定实现的媒体源，并进行设置
  @override
  setCurrentIndex(int index) async {
    super.setCurrentIndex(index);
    if (currentIndex >= 0 && currentIndex < playlist.length) {
      PlatformMediaSource? currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        AudioSource source =
            JustAudioSource.fromMediaSource(currentMediaSource);
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

  @override
  play() async {
    var audioSource = player.audioSource;
    if (audioSource != null) {
      await player.play();
    }
  }

  @override
  pause() async {
    await player.pause();
  }

  @override
  stop() async {
    await player.stop();
  }

  @override
  resume() async {
    await player.play();
  }

  @override
  dispose() async {
    await player.dispose();
    super.dispose();
  }

  @override
  seek(Duration? position, {int? index}) async {
    if (index != null) {
      setCurrentIndex(index);
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

  @override
  Future<double> getVolume() async {
    return Future.value(player.volume);
  }

  @override
  setVolume(double volume) async {
    await player.setVolume(volume);
  }

  Future<double> getSpeed() async {
    return Future.value(player.speed);
  }

  @override
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
