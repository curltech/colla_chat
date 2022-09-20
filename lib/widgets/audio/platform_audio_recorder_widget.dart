import 'dart:async';

import 'package:colla_chat/widgets/audio/platform_audio_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

class PlatformAudioRecorderWidget extends StatefulWidget {
  late final PlatformAudioRecorderController controller;
  final void Function(String path) onStop;

  PlatformAudioRecorderWidget(
      {Key? key,
      PlatformAudioRecorderController? controller,
      required this.onStop})
      : super(key: key) {
    controller = controller ?? PlatformAudioRecorderController();
  }

  @override
  State createState() => _PlatformAudioRecorderWidgetState();
}

class _PlatformAudioRecorderWidgetState
    extends State<PlatformAudioRecorderWidget> {
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _start() async {
    try {
      if (await widget.controller.hasPermission()) {
        // We don't do anything with this but printing
        final isSupported = await widget.controller.isEncoderSupported(
          codec: AudioEncoder.aacLc,
        );
        if (kDebugMode) {
          print('${AudioEncoder.aacLc.name} supported: $isSupported');
        }

        // final devs = await _audioRecorder.listInputDevices();
        // final isRecording = await _audioRecorder.isRecording();

        await widget.controller.start();
        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _recordDuration = 0;

    final path = await widget.controller.stop();

    if (path != null) {
      widget.onStop(path);
    }
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await widget.controller.pause();
  }

  Future<void> _resume() async {
    _startTimer();
    await widget.controller.resume();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildRecordStopControl(),
            const SizedBox(width: 20),
            _buildPauseResumeControl(),
            const SizedBox(width: 20),
            _buildText(),
          ],
        ),
        if (widget.controller.amplitude != null) ...[
          const SizedBox(height: 40),
          Text('Current: ${widget.controller.amplitude?.current ?? 0.0}'),
          Text('Max: ${widget.controller.amplitude?.max ?? 0.0}'),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (widget.controller.recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (widget.controller.recordState != RecordState.stop)
                ? _stop()
                : _start();
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    if (widget.controller.recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (widget.controller.recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (widget.controller.recordState == RecordState.pause)
                ? _resume()
                : _pause();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (widget.controller.recordState != RecordState.stop) {
      return _buildTimer();
    }

    return const Text("Waiting to record");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0' + numberStr;
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }
}
