import 'dart:io';
import 'dart:math';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder2/flutter_audio_recorder2.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:rxdart/rxdart.dart';

class JustAudio {
  static AudioSource audioSource(String filename) {
    AudioSource audioSource = AudioSource.uri(Uri.parse(filename));

    return audioSource;
  }

  static ConcatenatingAudioSource playlist(List<String> filenames) {
    List<AudioSource> audioSources = [];
    for (var filename in filenames) {
      audioSources.add(audioSource(filename));
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

  setAudioSource(String filename) async {
    if (filename.startsWith('assets/')) {
      await player.setAsset(filename);
    } else if (filename.startsWith('http')) {
      await player.setUrl(filename);
    } else {
      await player.setFilePath(filename);
    }
  }

  setAudioSources(
    List<String> filenames, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    // Load and play the playlist
    ConcatenatingAudioSource playlist = JustAudio.playlist(filenames);
    await player.setAudioSource(playlist,
        preload: preload,
        initialIndex: initialIndex,
        initialPosition: initialPosition);
  }

  setSourceFilePicker() async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path != null) {
      setAudioSource(path);
    }
  }

  play(String filename) async {
    await setAudioSource(filename);
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

  seekToNext() async {
    await player.seekToNext(); // Skip to the next item
  }

  seekToPrevious() async {
    await player.seekToPrevious(); // Skip to the previous item
  }

  seek(Duration? position, {int? index}) async {
    await player.seek(position,
        index: index); // Skip to the start of track3.mp3
  }

  setLoopMode(LoopMode mode) async {
    await player.setLoopMode(mode); // Set playlist to loop (off|all|one)
  }

  setShuffleModeEnabled(bool enabled) async {
    await player
        .setShuffleModeEnabled(enabled); // Shuffle playlist order (true|false)
  }

  add(ConcatenatingAudioSource playlist, AudioSource audioSource) async {
    // Update the playlist
    await playlist.add(audioSource);
  }

  insert(ConcatenatingAudioSource playlist, int index,
      AudioSource audioSource) async {
    await playlist.insert(index, audioSource);
  }

  removeAt(ConcatenatingAudioSource playlist, int index) async {
    await playlist.removeAt(index);
  }

  Duration? duration() {
    return player.duration;
  }

  int? currentIndex() {
    return player.currentIndex;
  }

  setVolume(double volume) async {
    await player.setVolume(volume);
  }

  setRate(double rate) async {
    await player.setSpeed(rate);
  }

  ///异步产生波形图形组件
  Future<StreamBuilder<WaveformProgress>> buildWaveformProgress(
      String filename) async {
    var data = await FileUtil.readFile(filename);
    final progressStream = BehaviorSubject<WaveformProgress>();
    final audioFile =
        File(p.join((await getTemporaryDirectory()).path, 'waveform.mp3'));
    try {
      await audioFile.writeAsBytes(data);
      final waveFile =
          File(p.join((await getTemporaryDirectory()).path, 'waveform.wave'));
      JustWaveform.extract(
        audioInFile: audioFile,
        waveOutFile: waveFile,
        zoom: const WaveformZoom.pixelsPerSecond(100),
      );
      progressStream.listen(progressStream.add,
          onError: progressStream.addError);
    } catch (e) {
      progressStream.addError(e);
    }
    return StreamBuilder<WaveformProgress>(
      stream: progressStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: Theme.of(context).textTheme.headline6,
              textAlign: TextAlign.center,
            ),
          );
        }
        final progress = snapshot.data?.progress ?? 0.0;
        final waveform = snapshot.data?.waveform;
        if (waveform == null) {
          return Center(
            child: Text(
              '${(100 * progress).toInt()}%',
              style: Theme.of(context).textTheme.headline6,
            ),
          );
        }
        return buildAudioWaveformPainter(
          context,
          waveform: waveform,
          start: Duration.zero,
          duration: waveform.duration,
        );
      },
    );
  }

  ///波形图形组件
  Widget buildAudioWaveformPainter(
    BuildContext context, {
    required Waveform waveform,
    required Duration start,
    required Duration duration,
    Color waveColor = Colors.blue,
    double scale = 1.0,
    double strokeWidth = 5.0,
    double pixelsPerStep = 8.0,
  }) {
    return ClipRect(
      child: CustomPaint(
        painter: AudioWaveformPainter(
          waveColor: waveColor,
          waveform: waveform,
          start: start,
          duration: duration,
          scale: scale,
          strokeWidth: strokeWidth,
          pixelsPerStep: pixelsPerStep,
        ),
      ),
    );
  }
}

class AudioWaveformPainter extends CustomPainter {
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Paint wavePaint;
  final Waveform waveform;
  final Duration start;
  final Duration duration;

  AudioWaveformPainter({
    required this.waveform,
    required this.start,
    required this.duration,
    Color waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 5.0,
    this.pixelsPerStep = 8.0,
  }) : wavePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero) return;

    double width = size.width;
    double height = size.height;

    final waveformPixelsPerWindow = waveform.positionToPixel(duration).toInt();
    final waveformPixelsPerDevicePixel = waveformPixelsPerWindow / width;
    final waveformPixelsPerStep = waveformPixelsPerDevicePixel * pixelsPerStep;
    final sampleOffset = waveform.positionToPixel(start);
    final sampleStart = -sampleOffset % waveformPixelsPerStep;
    for (var i = sampleStart.toDouble();
        i <= waveformPixelsPerWindow + 1.0;
        i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      final x = i / waveformPixelsPerDevicePixel;
      final minY = normalise(waveform.getPixelMin(sampleIdx), height);
      final maxY = normalise(waveform.getPixelMax(sampleIdx), height);
      canvas.drawLine(
        Offset(x + strokeWidth / 2, max(strokeWidth * 0.75, minY)),
        Offset(x + strokeWidth / 2, min(height - strokeWidth * 0.75, maxY)),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return false;
  }

  double normalise(int s, double height) {
    if (waveform.flags == 0) {
      final y = 32768 + (scale * s).clamp(-32768.0, 32767.0).toDouble();
      return height - 1 - y * height / 65536;
    } else {
      final y = 128 + (scale * s).clamp(-128.0, 127.0).toDouble();
      return height - 1 - y * height / 256;
    }
  }
}

///支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
class JustAudioRecorder {
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

  dispose() async {
    await recorder.stop();
  }
}
