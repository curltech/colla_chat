import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:colla_chat/widgets/media/audio/recorder/another_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/record_audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

///采用record和another实现的音频记录器组件
class PlatformAudioRecorder extends StatefulWidget {
  final AbstractAudioRecorderController audioRecorderController;
  final void Function(String filename)? onStop;
  final double width;
  final double height;

  PlatformAudioRecorder({
    Key? key,
    required this.audioRecorderController,
    this.width = 250,
    this.height = 48,
    this.onStop,
  }) : super(key: key) {
    if (audioRecorderController is RecordAudioRecorderController) {
      ///在macos上wav，aacLc可以录制和播放，pcm目前崩溃，opus，flac可以录制
      ///在windows上，aaclc，flac可以录制和播放，pcm，opus，wav尚未实现
      ///在ios上，aaclc，wav可以录制和播放，pcm崩溃，flac可以录制，opus尚未实现
      ///在android上，aaclc，可以录制和播放，wav,pcm,flac,opus尚未实现
      RecordAudioRecorderController recordAudioRecorderController =
          audioRecorderController as RecordAudioRecorderController;
      if (recordAudioRecorderController.encoder == AudioEncoder.pcm16bits) {
        if (platformParams.linux) {
          logger.e(
              'Not support pcm in ios and macos, please use another recorder');
        }
      }
    }
    if (audioRecorderController is AnotherAudioRecorderController) {
      if (!platformParams.mobile) {
        logger.e('Not support non mobile, please use record recorder');
      }
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
      if (widget.audioRecorderController is RecordAudioRecorderController) {
        RecordAudioRecorderController recordAudioRecorderController =
            widget.audioRecorderController as RecordAudioRecorderController;
        if (recordAudioRecorderController.encoder == AudioEncoder.pcm16bits) {
          if (platformParams.linux) {
            throw 'Not support pcm in ios and macos, please use another recorder';
          }
        }
      }
      if (widget.audioRecorderController is AnotherAudioRecorderController) {
        if (!platformParams.mobile) {
          throw 'Not support non mobile, please use record recorder';
        }
      }
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
    super.dispose();
  }

  Widget _buildRecorderWidget(BuildContext context) {
    var controlText =
        AppLocalizations.t(widget.audioRecorderController.durationText);
    Icon playIcon;
    String tooltip;
    if (widget.audioRecorderController.status == RecorderStatus.recording) {
      playIcon = const Icon(
        Icons.pause,
        size: 32,
        color: Colors.white,
      );
      tooltip = AppLocalizations.t('Pause');
    } else {
      playIcon = const Icon(
        Icons.play_arrow,
        size: 32,
        color: Colors.white,
      );
      tooltip = AppLocalizations.t('Play');
    }
    List<Widget> controls = [];
    if (widget.audioRecorderController.status == RecorderStatus.recording ||
        widget.audioRecorderController.status == RecorderStatus.pause) {
      controls.add(
        IconButton(
          tooltip: AppLocalizations.t('Stop'),
          icon: const Icon(
            Icons.stop,
            size: 32,
            color: Colors.white,
          ),
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
        tooltip: tooltip,
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
      CommonAutoSizeText(
        controlText,
        // style: const TextStyle(color: Colors.white),
      ),
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
