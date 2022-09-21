import 'dart:async';

import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/audio/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

///仅支持移动设备
class AnotherAudioRecorderController extends AbstractAudioRecorderController {
  AnotherAudioRecorder? recorder;
  Recording? _current;
  RecordingStatus _status = RecordingStatus.Unset;

  AnotherAudioRecorderController();

  @override
  Future<bool> hasPermission() async {
    bool hasPermission = await AnotherAudioRecorder.hasPermissions;

    return hasPermission;
  }

  @override
  RecorderStatus get status {
    if (_status == RecordingStatus.Recording) {
      return RecorderStatus.recording;
    }
    if (_status == RecordingStatus.Paused) {
      return RecorderStatus.pause;
    }
    if (_status == RecordingStatus.Stopped) {
      return RecorderStatus.stop;
    }

    return RecorderStatus.none;
  }

  @override
  Future<void> start({String? filename}) async {
    AudioFormat audioFormat = AudioFormat.AAC;
    int sampleRate = 16000;
    try {
      bool permission = await hasPermission();
      if (permission) {
        if (filename == null) {
          final dir = await getTemporaryDirectory();
          var name = DateUtil.currentDate();
          filename = '${dir.path}/$name.mp3';
        }
        recorder = AnotherAudioRecorder(filename,
            audioFormat: audioFormat, sampleRate: sampleRate);
        await recorder!.initialized;
        await recorder!.start();
        await super.start();
      }
      _current = recorder!.recording;
      _status = _current!.status!;
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  @override
  Future<String?> stop() async {
    _current = await recorder!.stop();
    _current = recorder!.recording;
    _status = _current!.status!;

    var filename = _current!.path;
    await super.stop();

    return filename;
  }

  @override
  Future<void> pause() async {
    await recorder!.pause();
    _current = recorder!.recording;
    _status = _current!.status!;
  }

  @override
  Future<void> resume() async {
    await recorder!.resume();
    _current = recorder!.recording;
    _status = _current!.status!;
  }

  Recording? get current {
    return _current;
  }

  @override
  dispose() async {
    await recorder!.stop();
    _current = recorder!.recording;
    _status = _current!.status!;
    super.dispose();
  }
}

class PlatformAnotherAudioRecorder extends StatefulWidget {
  late final AnotherAudioRecorderController controller;
  final void Function(String path)? onStop;

  PlatformAnotherAudioRecorder(
      {AnotherAudioRecorderController? controller, super.key, this.onStop}) {
    controller = controller ?? AnotherAudioRecorderController();
  }

  @override
  State<StatefulWidget> createState() => _PlatformAnotherAudioRecorderState();
}

class _PlatformAnotherAudioRecorderState
    extends State<PlatformAnotherAudioRecorder> {
  String controlText = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
    _init();
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

  _init() async {
    try {
      if (await widget.controller.hasPermission()) {
        await widget.controller.start();
        setState(() {});
      } else {
        DialogUtil.error(context, content: "You must accept permissions");
      }
    } catch (e) {
      logger.e(e);
    }
  }

  _start() async {
    try {
      await widget.controller?.start();
    } catch (e) {
      logger.e(e);
    }
  }

  _resume() async {
    await widget.controller?.resume();
  }

  _pause() async {
    await widget.controller?.pause();
  }

  _stop() async {
    if (widget.controller.status == RecorderStatus.recording ||
        widget.controller.status == RecorderStatus.pause) {
      final path = await widget.controller.stop();

      if (path != null) {
        widget.onStop!(path);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return _buildRecorderWidget(context);
  }
}
