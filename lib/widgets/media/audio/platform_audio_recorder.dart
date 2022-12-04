import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/audio/platform_another_audio_recorder.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

///支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
///在各种平台都支持的格式是m4a
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
  final double width;
  final double height;

  PlatformAudioRecorder(
      {Key? key,
      AbstractAudioRecorderController? controller,
      this.width = 150,
      this.height = 48,
      this.onStop})
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
    Icon playIcon;
    if (widget.controller.status == RecorderStatus.recording) {
      playIcon = const Icon(Icons.pause, size: 32);
    } else {
      playIcon = const Icon(Icons.play_arrow, size: 32);
    }
    List<Widget> controls = [];
    if (widget.controller.status == RecorderStatus.recording ||
        widget.controller.status == RecorderStatus.pause) {
      controls.add(
        InkWell(
          child: const Icon(Icons.stop, size: 32),
          onTap: () async {
            await _stop();
          },
        ),
      );
      controls.add(
        const SizedBox(
          width: 15,
        ),
      );
    }
    controls.add(
      InkWell(
        child: playIcon,
        onTap: () async {
          await _action();
        },
      ),
    );
    controls.add(
      const SizedBox(
        width: 15,
      ),
    );
    controls.add(
      Text(controlText),
    );
    var container = Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey,
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: controls),
    );
    return container;
  }
}
