import 'dart:async';

import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';

///仅支持移动设备，aac,wav两种格式，支持aac和wav
class AnotherAudioRecorderController extends AbstractAudioRecorderController {
  AnotherAudioRecorder? recorder;
  Recording? _current;
  AudioFormat audioFormat = AudioFormat.AAC;
  int sampleRate = 16000;

  AnotherAudioRecorderController();

  @override
  Future<bool> hasPermission() async {
    bool hasPermission = await AnotherAudioRecorder.hasPermissions;

    return hasPermission;
  }

  set state(RecordingStatus state) {
    if (state == RecordingStatus.Recording) {
      status = RecorderStatus.recording;
    } else if (state == RecordingStatus.Paused) {
      status = RecorderStatus.pause;
    } else {
      status = RecorderStatus.stop;
    }
  }

  @override
  Future<void> start({
    AudioFormat? audioFormat,
    int? sampleRate,
  }) async {
    try {
      bool permission = await hasPermission();
      if (permission) {
        String extension = 'ma4';
        AudioFormat format = audioFormat ?? this.audioFormat;
        if (format == AudioFormat.WAV) {
          extension = 'wav';
        }
        filename = await FileUtil.getTempFilename(extension: extension);
        recorder = AnotherAudioRecorder(filename!,
            audioFormat: format, sampleRate: sampleRate ?? this.sampleRate);
        await recorder!.initialized;
        await super.start();
        await recorder!.start();
      }
      _current = recorder!.recording;
      status = RecorderStatus.recording;
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  @override
  Future<String?> stop() async {
    if (status == RecorderStatus.recording || status == RecorderStatus.pause) {
      _current = await recorder!.stop();
      _current = recorder!.recording;

      var filename = _current!.path;
      logger.i('another audio recorder filename:$filename');
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
      await recorder!.pause();
      _current = recorder!.recording;
      status = RecorderStatus.pause;
    }
  }

  @override
  Future<void> resume() async {
    if (status == RecorderStatus.pause) {
      await recorder!.resume();
      _current = recorder!.recording;
      status = RecorderStatus.recording;
    }
  }

  Recording? get current {
    return _current;
  }

  @override
  dispose() async {
    if (recorder != null) {
      await stop();
      _current = null;
      recorder = null;
    }
    super.dispose();
  }
}
