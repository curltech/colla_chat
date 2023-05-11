import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:flutter/material.dart';

///采用record和another实现的音频记录器组件
class PlatformAudioRecorder extends StatefulWidget {
  final AbstractAudioRecorderController audioRecorderController;
  final void Function(String filename)? onStop;
  final double width;
  final double height;

  const PlatformAudioRecorder({
    Key? key,
    required this.audioRecorderController,
    this.width = 250,
    this.height = 48,
    this.onStop,
  }) : super(key: key);

  @override
  State createState() => _PlatformAudioRecorderState();
}

class _PlatformAudioRecorderState extends State<PlatformAudioRecorder> {
  late String controlText;

  @override
  void initState() {
    super.initState();
    widget.audioRecorderController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Future<void> _action() async {
    if (widget.audioRecorderController.status == RecorderStatus.recording) {
      await _pause();
    } else if (widget.audioRecorderController.status == RecorderStatus.stop) {
      await _start();
    } else if (widget.audioRecorderController.status == RecorderStatus.pause) {
      await _resume();
    }
  }

  Future<void> _start() async {
    try {
      await widget.audioRecorderController.start();
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> _stop() async {
    if (widget.audioRecorderController.status == RecorderStatus.recording ||
        widget.audioRecorderController.status == RecorderStatus.pause) {
      final filename = await widget.audioRecorderController.stop();

      if (filename != null && widget.onStop != null) {
        widget.onStop!(filename);
      }
    }
  }

  Future<void> _pause() async {
    await widget.audioRecorderController.pause();
  }

  Future<void> _resume() async {
    await widget.audioRecorderController.resume();
  }

  @override
  Widget build(BuildContext context) {
    return _buildRecorderWidget(context);
  }

  @override
  void dispose() {
    widget.audioRecorderController.removeListener(_update);
    widget.audioRecorderController.dispose();
    super.dispose();
  }

  Widget _buildRecorderWidget(BuildContext context) {
    var controlText = AppLocalizations.t(widget.audioRecorderController.durationText);
    Icon playIcon;
    if (widget.audioRecorderController.status == RecorderStatus.recording) {
      playIcon = const Icon(Icons.pause, size: 32);
    } else {
      playIcon = const Icon(Icons.play_arrow, size: 32);
    }
    List<Widget> controls = [];
    if (widget.audioRecorderController.status == RecorderStatus.recording ||
        widget.audioRecorderController.status == RecorderStatus.pause) {
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
      CommonAutoSizeText(controlText),
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
