import 'dart:io';
import 'dart:math';

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

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

///异步产生波形图形组件
Future<StreamBuilder<WaveformProgress>?> buildWaveformProgress(
    String filename) async {
  var data = await FileUtil.readFileAsBytes(filename);
  if (data == null) {
    return null;
  }
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
    progressStream.listen(progressStream.add, onError: progressStream.addError);
  } catch (e) {
    progressStream.addError(e);
  }
  return StreamBuilder<WaveformProgress>(
    stream: progressStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: CommonAutoSizeText(
            'Error: ${snapshot.error}',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        );
      }
      final progress = snapshot.data?.progress ?? 0.0;
      final waveform = snapshot.data?.waveform;
      if (waveform == null) {
        return Center(
          child: CommonAutoSizeText(
            '${(100 * progress).toInt()}%',
            style: Theme.of(context).textTheme.titleLarge,
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
