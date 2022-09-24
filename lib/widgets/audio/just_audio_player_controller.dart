import 'dart:typed_data';

import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/audio/platform_audio_player.dart';
import 'package:colla_chat/widgets/common/media_player_slider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:record/record.dart';
import 'package:rxdart/rxdart.dart';

///采用just_audio和record实现的音频的播放和记录，适用于多个平台
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
      if (filename.startsWith('assets/')) {
        audioSource = AudioSource.uri(Uri.parse(filename), tag: tag);
      } else if (filename.startsWith('http')) {
        audioSource = AudioSource.uri(Uri.parse(filename), tag: tag);
      } else {
        audioSource = AudioSource.uri(Uri.file(filename), tag: tag);
      }
    } else {
      data = data ?? Uint8List.fromList([]);
      filename = await FileUtil.writeTempFile(data, '');
      audioSource = AudioSource.uri(Uri.parse(filename), tag: tag);
    }

    return audioSource;
  }

  static Future<ConcatenatingAudioSource> playlist(
      List<String> filenames) async {
    List<AudioSource> audioSources = [];
    for (var filename in filenames) {
      audioSources.add(await audioSource(filename: filename));
    }
    final playlist = ConcatenatingAudioSource(
      // Start loading next item just before reaching it
      useLazyPreparation: true,
      // Customise the shuffle algorithm
      shuffleOrder: DefaultShuffleOrder(),
      // Specify the playlist items
      children: audioSources,
    );

    return playlist;
  }
}

///JustAudio音频播放器，Android, iOS, Linux, macOS, Windows, and web.
///还可以产生音频播放的波形图形组件
class JustAudioPlayerController extends AbstractMediaPlayerController {
  late AudioPlayer player;
  List<AudioSource> playlist = [];
  List<String> filenames = [];
  int? _currentIndex;

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

  @override
  setCurrentIndex(int? index) async {
    _currentIndex = index;
    if (_currentIndex != null) {
      AudioSource? source = playlist[_currentIndex!];
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
    super.dispose();
    await player.dispose();
  }

  @override
  next() async {
    if (_currentIndex != null && _currentIndex! < playlist.length) {
      setCurrentIndex(_currentIndex! + 1);
    }
    //await player.seekToNext();
  }

  @override
  previous() async {
    if (_currentIndex != null && _currentIndex! > 0) {
      setCurrentIndex(_currentIndex! - 1);
    }
    //await player.seekToPrevious();
  }

  @override
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

  @override
  setShuffleModeEnabled(bool enabled) async {
    await player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<Duration?> getDuration() async {
    return player.duration;
  }

  @override
  Future<Duration?> getPosition() async {
    return player.position;
  }

  @override
  Future<Duration?> getBufferedPosition() async {
    return player.bufferedPosition;
  }

  @override
  int? currentIndex() {
    return _currentIndex;
  }

  @override
  double getVolume() {
    return player.volume;
  }

  @override
  setVolume(double volume) async {
    await player.setVolume(volume);
  }

  @override
  double getSpeed() {
    return player.speed;
  }

  @override
  setSpeed(double speed) async {
    await player.setSpeed(speed);
  }

  @override
  add({String? filename, Uint8List? data}) async {
    if (filename != null && filenames.contains(filename)) {
      return;
    }
    AudioSource audioSource =
        await JustAudioSource.audioSource(filename: filename, data: data);
    playlist.add(audioSource);
    if (filename != null) {
      filenames.add(filename);
    } else {
      filenames.add(audioSource.toString());
    }
    await setCurrentIndex(playlist.length - 1);
  }

  @override
  insert(int index, {String? filename, Uint8List? data}) async {
    AudioSource audioSource =
        await JustAudioSource.audioSource(filename: filename, data: data);
    playlist.insert(index, audioSource);
    await setCurrentIndex(index);
  }

  @override
  remove(int index) async {
    playlist.removeAt(index);
    if (index == 0) {
      await setCurrentIndex(index);
    } else {
      await setCurrentIndex(index - 1);
    }
  }

  @override
  move(int initialIndex, int finalIndex) {
    var audioSource = playlist[initialIndex];
    playlist[initialIndex] = playlist[finalIndex];
    playlist[finalIndex] = audioSource;
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
}

///支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
class JustAudioRecorderController {
  final recorder = Record();

  Future<void> start({
    String? path,
    AudioEncoder encoder = AudioEncoder.aacLc,
    int bitRate = 128000,
    int samplingRate = 44100,
    int numChannels = 2,
    InputDevice? device,
  }) async {
    try {
      if (await recorder.hasPermission()) {
        final isSupported = await recorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );

        await recorder.start(
            path: path,
            encoder: encoder,
            bitRate: bitRate,
            samplingRate: samplingRate,
            numChannels: numChannels,
            device: device);
      }
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  Future<String?> stop() async {
    if (!await recorder.isRecording()) {
      return null;
    }

    return await recorder.stop();
  }

  Future<void> pause() async {
    await recorder.pause();
  }

  Future<void> resume() async {
    await recorder.resume();
  }

  dispose() async {
    await recorder.dispose();
  }
}
