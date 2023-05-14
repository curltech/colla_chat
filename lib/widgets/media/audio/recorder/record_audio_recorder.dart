import 'dart:async';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:record/record.dart';

///采用record实现的音频记录器，支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
///在各种平台都支持的格式是m4a
class RecordAudioRecorderController extends AbstractAudioRecorderController {
  final Record recorder = Record();

  AudioEncoder encoder = AudioEncoder.aacLc;
  int bitRate = 128000;
  int samplingRate = 44100;
  int numChannels = 2;
  InputDevice? device;

  StreamSubscription<RecordState>? stateSubscription;

  //振幅
  StreamSubscription<Amplitude>? amplitudeSubscription;
  Amplitude? _amplitude;

  RecordAudioRecorderController() {
    try {
      stateSubscription ??= recorder.onStateChanged().listen((recordState) {
        state = recordState;
      });

      amplitudeSubscription ??= recorder
          .onAmplitudeChanged(const Duration(milliseconds: 300))
          .listen((amp) {
        _amplitude = amp;
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

  /// 支持的录音音频格式
  Future<bool> isEncoderSupported(
      {AudioEncoder codec = AudioEncoder.aacLc}) async {
    return await recorder.isEncoderSupported(codec);
  }

  @override
  Future<void> start({
    String? filename,
    AudioEncoder? encoder,
    int? bitRate,
    int? samplingRate,
    int? numChannels,
    InputDevice? device,
  }) async {
    try {
      if (await recorder.hasPermission()) {
        this.filename = null;
        await super.start();
        await recorder.start(
            path: this.filename,
            encoder: encoder ?? this.encoder,
            bitRate: bitRate ?? this.bitRate,
            samplingRate: samplingRate ?? this.samplingRate,
            numChannels: numChannels ?? this.numChannels,
            device: device);
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
      logger.i('record audio recorder filename:$filename');
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
    if (stateSubscription != null) {
      stateSubscription!.cancel();
      stateSubscription = null;
    }
    if (amplitudeSubscription != null) {
      amplitudeSubscription!.cancel();
      amplitudeSubscription = null;
    }
    await stop();
    await recorder.dispose();
    super.dispose();
  }
}

final RecordAudioRecorderController globalRecordAudioRecorderController =
    RecordAudioRecorderController();
