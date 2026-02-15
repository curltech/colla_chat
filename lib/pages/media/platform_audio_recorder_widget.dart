import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:colla_chat/widgets/media/audio/player/blue_fire_audio_player.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/record_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/waveforms_audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

enum MediaRecorderType {
  record,
  another,
  waveform,
}

///平台标准的record的实现
class PlatformAudioRecorderWidget extends StatelessWidget with DataTileMixin {
  AbstractAudioRecorderController audioRecorderController =
      globalRecordAudioRecorderController;

  PlatformAudioRecorderWidget(
      {super.key, AbstractAudioRecorderController? controller});

  @override
  String get routeName => 'audio_recorder';

  @override
  IconData get iconData => Icons.record_voice_over;

  @override
  String get title => 'AudioRecorder';

  @override
  bool get withLeading => true;

  Widget _buildAudioFormats() {
    List<bool> isSelected = const [true, false, false, false, false];
    if (audioRecorderController is RecordAudioRecorderController) {
      RecordAudioRecorderController recordAudioRecorderController =
          audioRecorderController as RecordAudioRecorderController;
      if (recordAudioRecorderController.encoder.value == AudioEncoder.aacLc) {
        isSelected = const [true, false, false, false, false];
      }
      if (recordAudioRecorderController.encoder.value == AudioEncoder.flac) {
        isSelected = const [false, true, false, false, false];
      }
      if (recordAudioRecorderController.encoder.value ==
          AudioEncoder.pcm16bits) {
        isSelected = const [false, false, true, false, false];
      }
      if (recordAudioRecorderController.encoder.value == AudioEncoder.opus) {
        isSelected = const [false, false, false, true, false];
      }
      if (recordAudioRecorderController.encoder.value == AudioEncoder.wav) {
        isSelected = const [false, false, false, false, true];
      }
    }
    var toggleWidget = ToggleButtons(
      borderRadius: borderRadius,
      selectedBorderColor: Colors.white,
      borderColor: Colors.grey,
      color: Colors.white,
      isSelected: isSelected,
      onPressed: (int newIndex) {
        if (newIndex == 0) {
          if (audioRecorderController is RecordAudioRecorderController) {
            RecordAudioRecorderController recordAudioRecorderController =
                audioRecorderController as RecordAudioRecorderController;

            recordAudioRecorderController.encoder.value = AudioEncoder.aacLc;
          }
        } else if (newIndex == 1) {
          if (audioRecorderController is RecordAudioRecorderController) {
            RecordAudioRecorderController recordAudioRecorderController =
                audioRecorderController as RecordAudioRecorderController;

            recordAudioRecorderController.encoder.value = AudioEncoder.flac;
          }
        } else if (newIndex == 2) {
          if (audioRecorderController is RecordAudioRecorderController) {
            RecordAudioRecorderController recordAudioRecorderController =
                audioRecorderController as RecordAudioRecorderController;

            recordAudioRecorderController.encoder.value =
                AudioEncoder.pcm16bits;
          }
        } else if (newIndex == 3) {
          if (audioRecorderController is RecordAudioRecorderController) {
            RecordAudioRecorderController recordAudioRecorderController =
                audioRecorderController as RecordAudioRecorderController;

            recordAudioRecorderController.encoder.value = AudioEncoder.opus;
          }
        } else if (newIndex == 4) {
          if (audioRecorderController is RecordAudioRecorderController) {
            RecordAudioRecorderController recordAudioRecorderController =
                audioRecorderController as RecordAudioRecorderController;

            recordAudioRecorderController.encoder.value = AudioEncoder.wav;
          }
        }
      },
      children: <Widget>[
        Container(
            padding: const EdgeInsets.all(10.0),
            child: const AutoSizeText('aacLc')),
        Container(
            padding: const EdgeInsets.all(10.0),
            child: const AutoSizeText('flac')),
        Container(
            padding: const EdgeInsets.all(10.0),
            child: const AutoSizeText('pcm16bits')),
        Container(
            padding: const EdgeInsets.all(10.0),
            child: const AutoSizeText('opus')),
        Container(
            padding: const EdgeInsets.all(10.0),
            child: const AutoSizeText('wav')),
      ],
    );
    return SizedBox(
      height: 60,
      child: toggleWidget,
    );
  }

  List<Widget>? _buildRightWidgets() {
    if (platformParams.mobile) {
      List<bool> isSelected = const [true, false];
      if (audioRecorderController is WaveformsAudioRecorderController) {
        isSelected = const [false, true];
      }
      var toggleWidget = ToggleButtons(
        borderRadius: borderRadius,
        selectedBorderColor: Colors.white,
        borderColor: Colors.grey,
        isSelected: isSelected,
        onPressed: (int newIndex) {
          if (newIndex == 0) {
            audioRecorderController = globalRecordAudioRecorderController;
          } else if (newIndex == 1) {
            audioRecorderController = globalWaveformsAudioRecorderController;
          }
        },
        children: const <Widget>[
          Icon(
            Icons.record_voice_over_outlined,
            color: Colors.white,
          ),
          Icon(
            Icons.multitrack_audio,
            color: Colors.white,
          ),
        ],
      );
      List<Widget> children = [
        toggleWidget,
        const SizedBox(
          width: 5.0,
        )
      ];
      return children;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: true,
        rightWidgets: _buildRightWidgets(),
        child: Column(
          children: [
            _buildAudioFormats(),
            const Spacer(),
            PlatformAudioRecorder(
              onStop: (String filename) async {
                bool? confirm = await DialogUtil.confirm(
                    content:
                        '${AppLocalizations.t('Need you play record audio filename')} $filename?');
                if (confirm != null && confirm) {
                  BlueFireAudioPlayer audioPlayer = globalBlueFireAudioPlayer;
                  audioPlayer.play(filename);
                }
              },
              audioRecorderController: audioRecorderController,
            ),
            const Spacer(),
          ],
        ));
  }
}
