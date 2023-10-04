import 'dart:async';
import 'dart:io';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:record/record.dart';

///采用record实现的音频记录器，支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
///在各种平台都支持的格式是m4a
class RecordAudioRecorderController extends AbstractAudioRecorderController {
  final AudioRecorder _audioRecorder = AudioRecorder();

  AudioEncoder encoder = AudioEncoder.aacLc;
  int bitRate = 128000;
  int sampleRate = 44100;
  int numChannels = 2;
  InputDevice? device;

  StreamSubscription<RecordState>? stateSubscription;

  //振幅
  StreamSubscription<Amplitude>? amplitudeSubscription;
  Amplitude? _amplitude;

  RecordAudioRecorderController() {
    try {
      stateSubscription ??=
          _audioRecorder.onStateChanged().listen((recordState) {
        state = recordState;
      });

      amplitudeSubscription ??= _audioRecorder
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
    return await _audioRecorder.hasPermission();
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
    return await _audioRecorder.isEncoderSupported(codec);
  }

  @override
  Future<void> start({
    String? filename,
    AudioEncoder? encoder,
    int? bitRate,
    int? sampleRate,
    int? numChannels,
    InputDevice? device,
  }) async {
    try {
      if (await _audioRecorder.hasPermission()) {
        encoder = encoder ?? this.encoder;
        String extension = encoder.name;
        if (extension.startsWith('aac')) {
          extension = 'm4a';
        } else if (extension.startsWith('amr')) {
          extension = '3gp';
        } else if (extension.startsWith('pcm')) {
          extension = 'pcm';
        }
        this.filename = await FileUtil.getTempFilename(extension: extension);
        await super.start();
        RecordConfig recordConfig = RecordConfig(
          encoder: encoder,
          // bitRate: bitRate ?? this.bitRate,
          // sampleRate: sampleRate ?? this.sampleRate,
          // numChannels: numChannels ?? this.numChannels,
          // device: device
        );
        await _audioRecorder.start(
          recordConfig,
          path: this.filename!,
        );
        // final stream = await _audioRecorder.startStream(recordConfig);
        // stream.listen(
        //   (data) async {
        //     await FileUtil.writeFileAsBytes(data, this.filename!);
        //     logger.i('record audio recorder filename:${this.filename}');
        //   },
        //   onDone: () async {
        //     await super.stop();
        //     status = RecorderStatus.stop;
        //   },
        // );
        status = RecorderStatus.recording;
      }
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  @override
  Future<String?> stop() async {
    if (status == RecorderStatus.recording || status == RecorderStatus.pause) {
      String? filename = await _audioRecorder.stop();
      if (filename != null) {
        File file = File(filename);
        bool exists = file.existsSync();
        if (!exists) {
          return null;
        }
        int length = file.lengthSync();
        if (length < 256) {
          logger.e('record file is too small');
          file.deleteSync();
          return null;
        }
        logger.i('record audio recorder filename:$filename');
        this.filename = filename;
        await super.stop();
        status = RecorderStatus.stop;

        return filename;
      }
    }
    return null;
  }

  @override
  Future<void> pause() async {
    if (status == RecorderStatus.recording) {
      await _audioRecorder.pause();
      status = RecorderStatus.pause;
    }
  }

  @override
  Future<void> resume() async {
    if (status == RecorderStatus.pause) {
      await _audioRecorder.resume();
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
    await _audioRecorder.dispose();
    super.dispose();
  }
}

final RecordAudioRecorderController globalRecordAudioRecorderController =
    RecordAudioRecorderController();
