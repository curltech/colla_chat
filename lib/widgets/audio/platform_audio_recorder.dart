import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/audio/platform_another_audio_recorder.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum RecorderStatus { pause, recording, stop }

enum RecorderAudioFormat { wav, mp3 }

///支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
abstract class AbstractAudioRecorderController with ChangeNotifier {
  String? filename;
  RecorderStatus _status = RecorderStatus.stop;
  Timer? _timer;
  int _duration = -1;
  String _durationText = '';

  Future<bool> hasPermission();

  RecorderStatus get status {
    return _status;
  }

  set status(RecorderStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

  Future<void> start({String? filename}) async {
    if (filename == null) {
      final dir = await getTemporaryDirectory();
      var name = DateUtil.currentDate();
      filename = '${dir.path}/$name.mp3';
    }
    this.filename = filename;
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
        duration = duration + 1;
        notifyListeners();
      }
    });
  }

  void cancelTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      duration = 0;
    }
  }

  int get duration {
    return _duration;
  }

  set duration(int duration) {
    if (_duration != duration) {
      _duration = duration;
      _changeDurationText();
    }
  }

  String get durationText {
    return _durationText;
  }

  _changeDurationText() {
    var duration = Duration(seconds: _duration);
    var durationText = duration.toString();
    var pos = durationText.lastIndexOf('.');
    durationText = durationText.substring(0, pos);
    //'${duration.inHours}:${duration.inMinutes}:${duration.inSeconds}';

    _durationText = durationText;
  }
}

///支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
class PlatformAudioRecorderController extends AbstractAudioRecorderController {
  late final Record recorder;

  StreamSubscription<RecordState>? stateSubscription;
  StreamSubscription<Amplitude>? amplitudeSubscription;
  Amplitude? _amplitude;

  //RecordState _state = RecordState.stop;

  PlatformAudioRecorderController() {
    recorder = Record();
    try {
      stateSubscription ??= recorder.onStateChanged().listen((recordState) {
        state = recordState;
      });

      amplitudeSubscription ??= recorder
          .onAmplitudeChanged(const Duration(milliseconds: 300))
          .listen((amp) {
        _amplitude = amp;
        notifyListeners();
      });
    } catch (e) {
      logger.e(e);
    }
    //设置开始的计时提示
    duration = 0;
  }

  Amplitude? get amplitude {
    return _amplitude;
  }

  @override
  Future<bool> hasPermission() async {
    return await recorder.hasPermission();
  }

  set state(RecordState state) {
    if (state == RecordState.record) {
      status = RecorderStatus.recording;
    } else if (state == RecordState.pause) {
      status = RecorderStatus.pause;
    } else {
      status = RecorderStatus.stop;
    }
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
        status = RecorderStatus.recording;
      }
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  @override
  Future<String?> stop() async {
    if (status == RecorderStatus.recording || status == RecorderStatus.pause) {
      String? filename = await recorder.stop();
      logger.i('audio recorder filename:$filename');
      this.filename = filename;
      await super.stop();
      status = RecorderStatus.stop;

      return filename;
    }
    return null;
  }

  @override
  Future<void> pause() async {
    if (status == RecorderStatus.recording) {
      await recorder.pause();
      status = RecorderStatus.pause;
    }
  }

  @override
  Future<void> resume() async {
    if (status == RecorderStatus.pause) {
      await recorder.resume();
      status = RecorderStatus.recording;
    }
  }

  @override
  dispose() async {
    super.dispose();
    await recorder.dispose();
    status = RecorderStatus.stop;
    if (stateSubscription != null) {
      stateSubscription!.cancel();
      stateSubscription = null;
    }
    if (amplitudeSubscription != null) {
      amplitudeSubscription!.cancel();
      amplitudeSubscription = null;
    }
  }
}

///采用record实现的音频记录器组件
class PlatformAudioRecorder extends StatefulWidget {
  late final AbstractAudioRecorderController controller;
  final void Function(String filename)? onStop;

  PlatformAudioRecorder(
      {Key? key, AbstractAudioRecorderController? controller, this.onStop})
      : super(key: key) {
    if (controller == null) {
      if (platformParams.ios ||
          platformParams.android ||
          platformParams.web ||
          platformParams.windows ||
          platformParams.macos ||
          platformParams.linux) {
        this.controller = PlatformAudioRecorderController();
      } else {
        this.controller = AnotherAudioRecorderController();
      }
    } else {
      this.controller = controller;
    }
  }

  @override
  State createState() => _PlatformAudioRecorderState();
}

class _PlatformAudioRecorderState extends State<PlatformAudioRecorder> {
  late String controlText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Future<void> _action() async {
    if (widget.controller.status == RecorderStatus.recording) {
      await _pause();
    } else if (widget.controller.status == RecorderStatus.stop) {
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
      final filename = await widget.controller.stop();

      if (filename != null) {
        widget.onStop!(filename);
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
    var controlText = AppLocalizations.t(widget.controller.durationText);
    Icon icon;
    if (widget.controller.status == RecorderStatus.recording) {
      icon = const Icon(Icons.pause);
    } else {
      icon = const Icon(Icons.play_arrow);
    }
    return Column(children: [
      const Spacer(),
      TextButton(
        style: WidgetUtil.buildButtonStyle(
          maximumSize: const Size(150.0, 36.0),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon,
          const SizedBox(
            width: 15,
          ),
          Text(controlText),
        ]),
        onPressed: () async {
          await _action();
        },
        onLongPress: () async {
          await _stop();
        },
      )
    ]);
  }
}
