import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum RecorderStatus { none, pause, recording, stop }

enum RecorderAudioFormat { wav, mp3 }

///支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
abstract class AbstractAudioRecorderController with ChangeNotifier {
  String? _filename;
  Timer? _timer;
  int _duration = 0;
  String _durationText = '';

  Future<bool> hasPermission();

  RecorderStatus get status;

  String? get filename {
    return _filename;
  }

  Future<void> start({String? filename}) async {
    if (filename == null) {
      final dir = await getTemporaryDirectory();
      var name = DateUtil.currentDate();
      filename = '${dir.path}/$name.mp3';
    }
    _filename = filename;
    startTimer();
  }

  Future<String?> stop() async {
    cancelTimer();

    return null;
  }

  Future<void> pause();

  Future<void> resume();

  @override
  dispose() {
    super.dispose();
    cancelTimer();
  }

  void startTimer() {
    cancelTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (status == RecorderStatus.recording) {
        _duration++;
        _changeDurationText();
        notifyListeners();
      }
    });
  }

  void cancelTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      _duration = 0;
    }
  }

  int get duration {
    return _duration;
  }

  String get durationText {
    return _durationText;
  }

  _changeDurationText() {
    if (status == RecorderStatus.recording) {
      var duration = Duration(seconds: _duration);
      var durationText =
          '${duration.inHours}:${duration.inMinutes}:${duration.inSeconds}';

      _durationText = durationText;
    }
  }
}

///支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
class PlatformAudioRecorderController extends AbstractAudioRecorderController {
  final recorder = Record();
  StreamSubscription<RecordState>? stateSubscription;
  StreamSubscription<Amplitude>? amplitudeSubscription;
  Amplitude? _amplitude;
  RecordState _status = RecordState.stop;

  PlatformAudioRecorderController() {
    stateSubscription = recorder.onStateChanged().listen((recordState) {
      _status = recordState;
    });

    amplitudeSubscription = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) => _amplitude = amp);
  }

  Amplitude? get amplitude {
    return _amplitude;
  }

  @override
  Future<bool> hasPermission() async {
    return await recorder.hasPermission();
  }

  @override
  RecorderStatus get status {
    if (_status == RecordState.record) {
      return RecorderStatus.recording;
    }
    if (_status == RecordState.pause) {
      return RecorderStatus.pause;
    }
    if (_status == RecordState.stop) {
      return RecorderStatus.stop;
    }

    return RecorderStatus.none;
  }

  Future<bool> isEncoderSupported(
      {AudioEncoder codec = AudioEncoder.aacLc}) async {
    return await recorder.isEncoderSupported(codec);
  }

  @override
  Future<void> start({String? filename}) async {
    AudioEncoder encoder = AudioEncoder.aacLc;
    int bitRate = 128000;
    int samplingRate = 44100;
    int numChannels = 2;
    InputDevice? device;

    try {
      if (await recorder.hasPermission()) {
        await recorder.start(
            path: filename,
            encoder: encoder,
            bitRate: bitRate,
            samplingRate: samplingRate,
            numChannels: numChannels,
            device: device);
        await super.start(filename: filename);
      }
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  @override
  Future<String?> stop() async {
    if (!await recorder.isRecording()) {
      return null;
    }

    String? filename = await recorder.stop();
    _filename = filename;
    await super.stop();

    return filename;
  }

  @override
  Future<void> pause() async {
    await recorder.pause();
  }

  @override
  Future<void> resume() async {
    await recorder.resume();
  }

  @override
  dispose() async {
    super.dispose();
    await recorder.dispose();
  }
}

///采用record实现的音频记录器组件
class PlatformAudioRecorder extends StatefulWidget {
  late final PlatformAudioRecorderController controller;
  final void Function(String path)? onStop;

  PlatformAudioRecorder(
      {Key? key, PlatformAudioRecorderController? controller, this.onStop})
      : super(key: key) {
    controller = controller ?? PlatformAudioRecorderController();
  }

  @override
  State createState() => _PlatformAudioRecorderState();
}

class _PlatformAudioRecorderState extends State<PlatformAudioRecorder> {
  String controlText = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {
      if (widget.controller.status == RecorderStatus.recording) {
        controlText = widget.controller.durationText;
        controlText = '$controlText  ${AppLocalizations.t('pause')}';
      } else if (widget.controller.status == RecorderStatus.none ||
          widget.controller.status == RecorderStatus.stop) {
        controlText = AppLocalizations.t('start');
      } else if (widget.controller.status == RecorderStatus.pause) {
        controlText = AppLocalizations.t('resume');
      }
    });
  }

  Future<void> _action() async {
    if (widget.controller.status == RecorderStatus.recording) {
      await _pause();
    } else if (widget.controller.status == RecorderStatus.none ||
        widget.controller.status == RecorderStatus.stop) {
      await _start();
    } else if (widget.controller.status == RecorderStatus.pause) {
      await _resume();
    }
  }

  Future<void> _start() async {
    try {
      await widget.controller.start();
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> _stop() async {
    if (widget.controller.status == RecorderStatus.recording ||
        widget.controller.status == RecorderStatus.pause) {
      final path = await widget.controller.stop();

      if (path != null) {
        widget.onStop!(path);
      }
    }
  }

  Future<void> _pause() async {
    await widget.controller.pause();
  }

  Future<void> _resume() async {
    await widget.controller.resume();
  }

  @override
  Widget build(BuildContext context) {
    return _buildRecorderWidget(context);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  Widget _buildRecorderWidget(BuildContext context) {
    return TextButton(
      style: WidgetUtil.buildButtonStyle(),
      child: Text(controlText),
      onPressed: () async {
        await _action();
      },
      onLongPress: () async {
        await _stop();
      },
    );
  }
}
