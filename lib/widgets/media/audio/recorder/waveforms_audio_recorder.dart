import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:path_provider/path_provider.dart';

///仅支持移动设备，带有波形图案的录音器，aac,wav两种格式
class WaveformsAudioRecorderController extends AbstractAudioRecorderController {
  late RecorderController recorderController;

  WaveformsAudioRecorderController() {
    recorderController = RecorderController();
  }

  @override
  Future<bool> hasPermission() async {
    bool hasPermission = recorderController.hasPermission;

    return Future.value(hasPermission);
  }

  set state(RecorderState state) {
    if (state == RecorderState.recording) {
      status = RecorderStatus.recording;
    } else if (state == RecorderState.paused) {
      status = RecorderStatus.pause;
    } else if (state == RecorderState.stopped) {
      status = RecorderStatus.stop;
    } else {
      status = RecorderStatus.stop;
    }
  }

  @override
  Future<void> start() async {
    try {
      bool permission = await hasPermission();
      if (permission) {
        if (filename == null) {
          final dir = await getTemporaryDirectory();
          var name = DateUtil.currentDate();
          filename = '${dir.path}/$name.ma4';
        }
        await recorderController.record(path: filename);
        await super.start();
      }
      status = RecorderStatus.recording;
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  @override
  Future<String?> stop() async {
    if (status == RecorderStatus.recording || status == RecorderStatus.pause) {
      String? filename = await recorderController.stop();
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
      await recorderController.pause();
      status = RecorderStatus.pause;
    }
  }

  @override
  Future<void> resume() async {
    if (status == RecorderStatus.pause) {
      await recorderController.record();
      status = RecorderStatus.recording;
    }
  }

  @override
  dispose() async {
    recorderController.dispose();
    status = RecorderStatus.stop;
    super.dispose();
  }
}
