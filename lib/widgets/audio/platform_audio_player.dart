import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/audio/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/audio/blue_fire_audio_player_controller.dart';
import 'package:colla_chat/widgets/audio/just_audio_player.dart';
import 'package:colla_chat/widgets/audio/just_audio_player_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

abstract class AbstractAudioPlayerController {
  open({
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  });

  play();

  pause();

  stop();

  resume();

  dispose();

  next();

  previous();

  seek(Duration? position, {int? index});

  setShuffleModeEnabled(bool enabled);

  Future<Duration?> getDuration();

  int? currentIndex();

  setVolume(double volume);

  setRate(double rate);

  add({String? filename, Uint8List? data});

  insert(int index, {String? filename, Uint8List? data});

  remove(int index);

  sourceFilePicker({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.audio,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = true,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async {
    final filenames =
        await FileUtil.pickFiles(allowMultiple: allowMultiple, type: type);
    if (filenames.isNotEmpty) {
      for (var filename in filenames) {
        add(filename: filename);
      }
    }
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

class PlatformAudioPlayerController extends AbstractAudioPlayerController {
  late AbstractAudioPlayerController controller;

  PlatformAudioPlayerController() {
    if (platformParams.ios || platformParams.android || platformParams.web) {
      controller = JustAudioPlayerController();
    } else {
      controller = BlueFireAudioPlayerController();
    }
  }

  @override
  open({
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    await controller.open();
  }

  @override
  play() async {
    await controller.play();
  }

  @override
  pause() async {
    await controller.pause();
  }

  @override
  stop() async {
    await controller.stop();
  }

  @override
  resume() async {
    await controller.play();
  }

  @override
  dispose() async {
    await controller.dispose();
  }

  @override
  next() async {
    await controller.next();
  }

  @override
  previous() async {
    await controller.previous();
  }

  @override
  seek(Duration? position, {int? index}) async {
    await controller.seek(position, index: index);
  }

  @override
  setShuffleModeEnabled(bool enabled) async {
    await controller.setShuffleModeEnabled(enabled);
  }

  @override
  Future<Duration?> getDuration() {
    return controller.getDuration();
  }

  @override
  int? currentIndex() {
    return controller.currentIndex();
  }

  @override
  setVolume(double volume) async {
    await controller.setVolume(volume);
  }

  @override
  setRate(double rate) async {
    await controller.setRate(rate);
  }

  @override
  add({String? filename, Uint8List? data}) async {
    await controller.add(filename: filename, data: data);
  }

  @override
  insert(int index, {String? filename, Uint8List? data}) async {
    await controller.insert(index, filename: filename, data: data);
  }

  @override
  remove(int index) async {
    await controller.remove(index);
  }
}

///平台标准的audio-player的实现，
class PlatformAudioPlayer extends StatefulWidget {
  late final PlatformAudioPlayerController controller;

  PlatformAudioPlayer({Key? key, PlatformAudioPlayerController? controller})
      : super(key: key) {
    this.controller = controller ?? PlatformAudioPlayerController();
  }

  @override
  State createState() => _PlatformAudioPlayerState();
}

class _PlatformAudioPlayerState extends State<PlatformAudioPlayer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PlatformAudioPlayerController platformAudioPlayerController =
        PlatformAudioPlayerController();
    if (platformParams.ios || platformParams.android || platformParams.web) {
      var player = JustAudioPlayer(
          controller: platformAudioPlayerController.controller
              as JustAudioPlayerController);
      return player;
    } else {
      var player = BlueFireAudioPlayer(
        controller: platformAudioPlayerController.controller
            as BlueFireAudioPlayerController,
      );
      return player;
    }
  }
}
