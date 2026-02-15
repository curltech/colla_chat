import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:colla_chat/widgets/media/audio/recorder/record_audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

///采用record和another实现的音频记录器组件
class PlatformAudioRecorder extends StatelessWidget {
  final AbstractAudioRecorderController audioRecorderController;
  final void Function(String filename)? onStop;
  final double width;
  final double height;

  PlatformAudioRecorder({
    super.key,
    required this.audioRecorderController,
    this.width = 250,
    this.height = 48,
    this.onStop,
  }) {
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
  }

  Future<void> _action() async {
    if (audioRecorderController.status == RecorderStatus.recording) {
      await _pause();
    } else if (audioRecorderController.status == RecorderStatus.stop) {
      await _start();
    } else if (audioRecorderController.status == RecorderStatus.pause) {
      await _resume();
    }
  }

  Future<void> _start() async {
    try {
      if (audioRecorderController is RecordAudioRecorderController) {
        RecordAudioRecorderController recordAudioRecorderController =
            audioRecorderController as RecordAudioRecorderController;
        if (recordAudioRecorderController.encoder == AudioEncoder.pcm16bits) {
          if (platformParams.linux) {
            throw 'Not support pcm in ios and macos, please use another recorder';
          }
        }
      }
      await audioRecorderController.start();
    } catch (e) {
      logger.e(e.toString());
    }
  }

  Future<void> _stop() async {
    if (audioRecorderController.status == RecorderStatus.recording ||
        audioRecorderController.status == RecorderStatus.pause) {
      final filename = await audioRecorderController.stop();

      if (filename != null && onStop != null) {
        onStop!(filename);
      }
    }
  }

  Future<void> _pause() async {
    await audioRecorderController.pause();
  }

  Future<void> _resume() async {
    await audioRecorderController.resume();
  }

  Widget _buildRecorderWidget(BuildContext context) {
    var controlText = AppLocalizations.t(audioRecorderController.durationText);
    Icon playIcon;
    String tooltip;
    if (audioRecorderController.status == RecorderStatus.recording) {
      playIcon = const Icon(
        Icons.pause,
        size: 32,
        //color: Colors.white,
      );
      tooltip = AppLocalizations.t('Pause');
    } else {
      playIcon = const Icon(
        Icons.play_arrow,
        size: 32,
        //color: Colors.white,
      );
      tooltip = AppLocalizations.t('Play');
    }
    List<Widget> controls = [];
    if (audioRecorderController.status == RecorderStatus.recording ||
        audioRecorderController.status == RecorderStatus.pause) {
      controls.add(
        IconButton(
          tooltip: AppLocalizations.t('Stop'),
          icon: const Icon(
            Icons.stop,
            size: 32,
            //color: Colors.white,
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
      AutoSizeText(
        controlText,
        // style: const TextStyle(color: Colors.white),
      ),
    );
    var container = SizedBox(
      width: width,
      height: height,
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: controls),
    );
    return container;
  }

  @override
  Widget build(BuildContext context) {
    return _buildRecorderWidget(context);
  }
}
