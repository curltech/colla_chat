import 'package:colla_chat/plugin/logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_audio_recorder2/flutter_audio_recorder2.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

///JustAudio音频播放器，Android, iOS, Linux, macOS, Windows, and web.
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

  setSource(String filename) async {
    if (filename.startsWith('assets/')) {
      await player.setAsset(filename);
    } else if (filename.startsWith('http')) {
      await player.setUrl(filename);
    } else {
      await player.setFilePath(filename);
    }
  }

  setSourceFilePicker() async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path != null) {
      setSource(path);
    }
  }

  play(String filename) async {
    await player.play();
  }

  pause() async {
    await player.pause(); // will resume where left off
  }

  stop() async {
    await player.stop(); // will resume from beginning
  }

  resume() async {
    await player.play();
  }

  dispose() async {
    await player.dispose();
  }

  Duration? duration() {
    return player.duration;
  }

  int? currentIndex() {
    return player.currentIndex;
  }

  seek(Duration position) async {
    await player.seek(position);
  }

  setVolume(double volume) async {
    await player.setVolume(volume);
  }

  setRate(double rate) async {
    await player.setSpeed(rate);
  }

  setLoopMode(LoopMode mode) async {
    await player.setLoopMode(mode); // half speed
  }
}

///支持多种设备，windows测试通过
class JustAudioRecorder {
  final recorder = Record();

  dispose() async {
    await recorder.dispose();
  }

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
}

///仅支持移动设备
class PlatformFlutterAudioRecorder2 {
  late FlutterAudioRecorder2 recorder;

  init(
    String path, {
    AudioFormat? audioFormat,
    int sampleRate = 16000,
  }) {
    recorder = FlutterAudioRecorder2(path,
        audioFormat: audioFormat, sampleRate: sampleRate);
  }

  dispose() async {
    await recorder.stop();
  }

  Future<void> start(
    String path, {
    AudioFormat? audioFormat,
    int sampleRate = 16000,
  }) async {
    try {
      bool? hasPermission = await FlutterAudioRecorder2.hasPermissions;
      if (hasPermission!) {
        recorder = FlutterAudioRecorder2(path,
            audioFormat: audioFormat, sampleRate: sampleRate);
        await recorder.initialized;
        await recorder.start();
      }
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  Future<Recording?> stop() async {
    return await recorder.stop();
  }

  Future<void> pause() async {
    await recorder.pause();
  }

  Future<void> resume() async {
    await recorder.resume();
  }
}
