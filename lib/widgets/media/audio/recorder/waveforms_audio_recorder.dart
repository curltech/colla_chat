import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
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
      status.value = RecorderStatus.recording;
    } else if (state == RecorderState.paused) {
      status.value = RecorderStatus.pause;
    } else if (state == RecorderState.stopped) {
      status.value = RecorderStatus.stop;
    } else {
      status.value = RecorderStatus.stop;
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
      status.value = RecorderStatus.recording;
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  @override
  Future<String?> stop() async {
    if (status.value == RecorderStatus.recording ||
        status.value == RecorderStatus.pause) {
      String? filename = await recorderController.stop();
      logger.i('audio recorder filename:$filename');
      this.filename = filename;
      await super.stop();
      status.value = RecorderStatus.stop;

      return filename;
    }
    return null;
  }

  @override
  Future<void> pause() async {
    if (status.value == RecorderStatus.recording) {
      await recorderController.pause();
      status.value = RecorderStatus.pause;
    }
  }

  @override
  Future<void> resume() async {
    if (status.value == RecorderStatus.pause) {
      await recorderController.record();
      status.value = RecorderStatus.recording;
    }
  }

  Future<void> dispose() async {
    recorderController.dispose();
    status.value = RecorderStatus.stop;
  }
}

final WaveformsAudioRecorderController globalWaveformsAudioRecorderController =
    WaveformsAudioRecorderController();
