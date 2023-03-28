import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/media/platform_audio_recorder_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:colla_chat/widgets/media/audio/recorder/another_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/record_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/waveforms_audio_recorder.dart';
import 'package:flutter/material.dart';

///采用record和another实现的音频记录器组件
class PlatformAudioRecorder extends StatefulWidget {
  final MediaRecorderType? mediaRecorderType;
  late final AbstractAudioRecorderController controller;
  final void Function(String filename)? onStop;
  final double width;
  final double height;

  PlatformAudioRecorder({
    Key? key,
    AbstractAudioRecorderController? controller,
    this.width = 250,
    this.height = 48,
    this.onStop,
    this.mediaRecorderType = MediaRecorderType.record,
  }) : super(key: key) {
    if (controller == null) {
      if (mediaRecorderType == MediaRecorderType.record) {
        this.controller = RecordAudioRecorderController();
      } else if (mediaRecorderType == MediaRecorderType.another) {
        this.controller = AnotherAudioRecorderController();
      } else if (mediaRecorderType == MediaRecorderType.waveform) {
        this.controller = WaveformsAudioRecorderController();
      } else {
        this.controller = RecordAudioRecorderController();
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

      if (filename != null && widget.onStop != null) {
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
    widget.controller.dispose();
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
        IconButton(
          icon: const Icon(Icons.stop, size: 32),
          onPressed: () async {
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
      IconButton(
        icon: playIcon,
        onPressed: () async {
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
    var container = SizedBox(
      width: widget.width,
      height: widget.height,
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: controls),
    );
    return container;
  }
}
