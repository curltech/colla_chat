import 'dart:typed_data';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/audio/platform_audio_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

///采用just_audio和record实现的音频的播放和记录，适用于多个平台
class JustAudioSource {
  static Future<AudioSource> audioSource(
      {String? filename, Uint8List? data}) async {
    AudioSource audioSource;
    if (filename != null) {
      audioSource = AudioSource.uri(Uri.parse(filename));
    } else {
      data = data ?? Uint8List.fromList([]);
      filename = await FileUtil.writeTempFile(data, '');
      audioSource = AudioSource.uri(Uri.parse(filename));
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
class JustAudioPlayerController extends AbstractAudioPlayerController {
  late AudioPlayer player;
  ConcatenatingAudioSource playlist = ConcatenatingAudioSource(
    // Start loading next item just before reaching it
    useLazyPreparation: true,
    // Customise the shuffle algorithm
    shuffleOrder: DefaultShuffleOrder(),
    // Specify the playlist items
    children: [],
  );

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
  }

  @override
  open({
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    await player.setAudioSource(playlist,
        preload: preload,
        initialIndex: initialIndex,
        initialPosition: initialPosition);
  }

  @override
  play() async {
    await player.play();
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
  }

  @override
  next() async {
    await player.seekToNext();
  }

  @override
  previous() async {
    await player.seekToPrevious();
  }

  @override
  seek(Duration? position, {int? index}) async {
    await player.seek(position, index: index);
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
  int? currentIndex() {
    return player.currentIndex;
  }

  @override
  setVolume(double volume) async {
    await player.setVolume(volume);
  }

  @override
  setRate(double rate) async {
    await player.setSpeed(rate);
  }

  @override
  add({String? filename, Uint8List? data}) async {
    AudioSource audioSource =
        await JustAudioSource.audioSource(filename: filename, data: data);
    await playlist.add(audioSource);
  }

  @override
  insert(int index, {String? filename, Uint8List? data}) async {
    AudioSource audioSource =
        await JustAudioSource.audioSource(filename: filename, data: data);
    await playlist.insert(index, audioSource);
  }

  @override
  remove(int index) async {
    await playlist.removeAt(index);
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
