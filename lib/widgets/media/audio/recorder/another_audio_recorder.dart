import 'dart:async';

import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:path_provider/path_provider.dart';

///仅支持移动设备，aac,wav两种格式，支持mp3
class AnotherAudioRecorderController extends AbstractAudioRecorderController {
  AnotherAudioRecorder? recorder;
  Recording? _current;

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
  Future<void> start() async {
    AudioFormat audioFormat = AudioFormat.AAC;
    int sampleRate = 16000;
    try {
      bool permission = await hasPermission();
      if (permission) {
        if (filename == null) {
          final dir = await getTemporaryDirectory();
          var name = DateUtil.currentDate();
          filename = '${dir.path}/$name.ma4';
        }
        recorder = AnotherAudioRecorder(filename!,
            audioFormat: audioFormat, sampleRate: sampleRate);
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
