import 'dart:async';

import 'package:colla_chat/plugin/logger.dart';
import 'package:record/record.dart';

///支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
abstract class AbstractAudioRecorderController {
  Future<void> start({
    String? path,
    AudioEncoder encoder = AudioEncoder.aacLc,
    int bitRate = 128000,
    int samplingRate = 44100,
    int numChannels = 2,
    InputDevice? device,
  });

  Future<String?> stop();

  Future<void> pause();

  Future<void> resume();

  dispose();
}

///支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
class PlatformAudioRecorderController {
  final recorder = Record();
  StreamSubscription<RecordState>? stateSubscription;
  StreamSubscription<Amplitude>? amplitudeSubscription;
  Amplitude? _amplitude;
  RecordState _recordState = RecordState.stop;

  PlatformAudioRecorderController() {
    stateSubscription = recorder.onStateChanged().listen((recordState) {
      _recordState = recordState;
    });

    amplitudeSubscription = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) => _amplitude = amp);
  }

  Amplitude? get amplitude {
    return _amplitude;
  }

  RecordState get recordState {
    return _recordState;
  }

  Future<bool> hasPermission() async {
    return await recorder.hasPermission();
  }

  Future<bool> isEncoderSupported(
      {AudioEncoder codec = AudioEncoder.aacLc}) async {
    return await recorder.isEncoderSupported(codec);
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

  dispose() async {
    await recorder.dispose();
  }
}
