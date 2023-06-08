import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/abstract_audio_player_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';
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
  }) : super() {
    player = AudioPlayer(
        userAgent: userAgent,
        handleInterruptions: handleInterruptions,
        androidApplyAudioAttributes: androidApplyAudioAttributes,
        handleAudioSessionActivation: handleAudioSessionActivation,
        audioLoadConfiguration: audioLoadConfiguration,
        audioPipeline: audioPipeline,
        androidOffloadSchedulingEnabled: androidOffloadSchedulingEnabled);
  }

  initSession() {
    AudioSession.instance.then((audioSession) async {
      // This line configures the app's audio session, indicating to the OS the
      // type of audio we intend to play. Using the "speech" recipe rather than
      // "music" since we are playing a podcast.
      await audioSession.configure(const AudioSessionConfiguration.speech());
      await audioSession.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
      // Listen to audio interruptions and pause or duck as appropriate.
      audioSession.becomingNoisyEventStream.listen((_) {
        //_player.pause();
      });
      audioSession.interruptionEventStream.listen((event) {
        logger.i('interruption begin: ${event.begin}');
        logger.i('interruption type: ${event.type}');
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              if (audioSession.androidAudioAttributes!.usage ==
                  AndroidAudioUsage.game) {
                player.setVolume(player.volume / 2);
              }
              //playInterrupted = false;
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              if (player.playing) {
                player.pause();
                //playInterrupted = true;
              }
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              player.setVolume(min(1.0, player.volume * 2));
              //playInterrupted = false;
              break;
            case AudioInterruptionType.pause:
              // if (playInterrupted) player.play();
              // playInterrupted = false;
              break;
            case AudioInterruptionType.unknown:
              // playInterrupted = false;
              break;
          }
        }
      });
      audioSession.devicesChangedEventStream.listen((event) {
        logger.i('Devices added: ${event.devicesAdded}');
        logger.i('Devices removed: ${event.devicesRemoved}');
      });
      await audioSession.setActive(true);
    });
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

final JustAudioPlayer globalJustAudioPlayer = JustAudioPlayer();

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
  JustAudioPlayer? player;

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
    this.player,
  }) {
    this.player ??= JustAudioPlayer(
        userAgent: userAgent,
        handleInterruptions: handleInterruptions,
        androidApplyAudioAttributes: androidApplyAudioAttributes,
        handleAudioSessionActivation: handleAudioSessionActivation,
        audioLoadConfiguration: audioLoadConfiguration,
        audioPipeline: audioPipeline,
        androidOffloadSchedulingEnabled: androidOffloadSchedulingEnabled);
    AudioPlayer player = this.player!.player;
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
    if (index >= -1 && index < playlist.length && currentIndex != index) {
      close();
      await super.setCurrentIndex(index);
      notifyListeners();
      if (autoplay) {
        play();
      }
    }
  }

  @override
  play() async {
    if (currentIndex >= 0 && currentIndex < playlist.length) {
      PlatformMediaSource? currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        try {
          await player!.play(currentMediaSource.filename);
        } catch (e) {
          logger.e('$e');
        }
      }
    }
  }

  @override
  pause() async {
    await player!.pause();
  }

  @override
  stop() async {
    await player!.stop();
  }

  @override
  resume() async {
    await play();
  }

  @override
  dispose() async {
    await player!.player.dispose();
    super.dispose();
  }

  @override
  seek(Duration? position, {int? index}) async {
    if (index != null) {
      setCurrentIndex(index);
    }
    if (position != null) {
      try {
        await player!.player.seek(position, index: index);
      } catch (e) {
        logger.e('seek failure:$e');
      }
    }
  }

  setLoopMode(LoopMode mode) async {
    await player!.player.setLoopMode(mode);
  }

  Future<Duration?> getDuration() async {
    return player!.player.duration;
  }

  Future<Duration?> getPosition() async {
    return player!.player.position;
  }

  Future<Duration?> getBufferedPosition() async {
    return player!.player.bufferedPosition;
  }

  @override
  Future<double> getVolume() async {
    return Future.value(player!.player.volume);
  }

  @override
  setVolume(double volume) async {
    await player!.player.setVolume(volume);
  }

  @override
  Future<double> getSpeed() async {
    return Future.value(player!.player.speed);
  }

  @override
  setSpeed(double speed) async {
    await player!.player.setSpeed(speed);
  }

  /// Collects the data useful for displaying in a seek bar, using a handy
  /// feature of rx_dart to combine the 3 streams of interest into one.
  Stream<PositionData> get positionDataStream {
    return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player!.player.positionStream,
        player!.player.bufferedPositionStream,
        player!.player.durationStream,
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
    return super.buildMediaPlayer(
        key: key,
        showClosedCaptionButton: showClosedCaptionButton,
        showFullscreenButton: showFullscreenButton,
        showVolumeButton: showVolumeButton);
  }
}

final JustAudioPlayerController globalJustAudioPlayerController =
    JustAudioPlayerController();
