import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
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
class PlatformAudioRecorderWidget extends StatefulWidget with TileDataMixin {
  AbstractAudioRecorderController audioRecorderController =
      globalRecordAudioRecorderController;

  PlatformAudioRecorderWidget(
      {Key? key, AbstractAudioRecorderController? controller})
      : super(key: key);

  @override
  State createState() => _PlatformAudioRecorderWidgetState();

  @override
  String get routeName => 'audio_recorder';

  @override
  IconData get iconData => Icons.record_voice_over;

  @override
  String get title => 'AudioRecorder';

  @override
  bool get withLeading => true;
}

class _PlatformAudioRecorderWidgetState
    extends State<PlatformAudioRecorderWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildAudioFormats() {
    List<bool> isSelected = const [true, false, false, false];
    if (widget.audioRecorderController is RecordAudioRecorderController) {
      RecordAudioRecorderController recordAudioRecorderController =
          widget.audioRecorderController as RecordAudioRecorderController;
      if (recordAudioRecorderController.encoder == AudioEncoder.aacLc) {
        isSelected = const [true, false, false, false, false];
      }
      if (recordAudioRecorderController.encoder == AudioEncoder.aacHe) {
        isSelected = const [false, true, false, false, false];
      }
      if (recordAudioRecorderController.encoder == AudioEncoder.pcm16bits) {
        isSelected = const [false, false, true, false, false];
      }
      if (recordAudioRecorderController.encoder == AudioEncoder.opus) {
        isSelected = const [false, false, false, true, false];
      }
      if (recordAudioRecorderController.encoder == AudioEncoder.wav) {
        isSelected = const [false, false, false, false, true];
      }
    }
    var toggleWidget = ToggleButtons(
      selectedBorderColor: Colors.white,
      borderColor: Colors.grey,
      color: Colors.white,
      isSelected: isSelected,
      onPressed: (int newIndex) {
        if (newIndex == 0) {
          if (widget.audioRecorderController is RecordAudioRecorderController) {
            RecordAudioRecorderController recordAudioRecorderController =
                widget.audioRecorderController as RecordAudioRecorderController;
            setState(() {
              recordAudioRecorderController.encoder = AudioEncoder.aacLc;
            });
          }
        } else if (newIndex == 1) {
          if (widget.audioRecorderController is RecordAudioRecorderController) {
            RecordAudioRecorderController recordAudioRecorderController =
                widget.audioRecorderController as RecordAudioRecorderController;
            setState(() {
              recordAudioRecorderController.encoder = AudioEncoder.aacHe;
            });
          }
        } else if (newIndex == 2) {
          if (widget.audioRecorderController is RecordAudioRecorderController) {
            RecordAudioRecorderController recordAudioRecorderController =
                widget.audioRecorderController as RecordAudioRecorderController;
            setState(() {
              recordAudioRecorderController.encoder = AudioEncoder.pcm16bits;
            });
          }
        } else if (newIndex == 3) {
          if (widget.audioRecorderController is RecordAudioRecorderController) {
            RecordAudioRecorderController recordAudioRecorderController =
                widget.audioRecorderController as RecordAudioRecorderController;
            setState(() {
              recordAudioRecorderController.encoder = AudioEncoder.opus;
            });
          }
        } else if (newIndex == 4) {
          if (widget.audioRecorderController is RecordAudioRecorderController) {
            RecordAudioRecorderController recordAudioRecorderController =
                widget.audioRecorderController as RecordAudioRecorderController;
            setState(() {
              recordAudioRecorderController.encoder = AudioEncoder.wav;
            });
          }
        }
      },
      children: <Widget>[
        Container(
            padding: const EdgeInsets.all(10.0),
            child: const CommonAutoSizeText('aacLc')),
        Container(
            padding: const EdgeInsets.all(10.0),
            child: const CommonAutoSizeText('aacHe')),
        Container(
            padding: const EdgeInsets.all(10.0),
            child: const CommonAutoSizeText('pcm16bits')),
        Container(
            padding: const EdgeInsets.all(10.0),
            child: const CommonAutoSizeText('opus')),
        Container(
            padding: const EdgeInsets.all(10.0),
            child: const CommonAutoSizeText('wav')),
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
      if (widget.audioRecorderController is WaveformsAudioRecorderController) {
        isSelected = const [false, true];
      }
      var toggleWidget = ToggleButtons(
        selectedBorderColor: Colors.white,
        borderColor: Colors.grey,
        isSelected: isSelected,
        onPressed: (int newIndex) {
          if (newIndex == 0) {
            setState(() {
              widget.audioRecorderController =
                  globalRecordAudioRecorderController;
            });
          } else if (newIndex == 1) {
            setState(() {
              widget.audioRecorderController =
                  globalWaveformsAudioRecorderController;
            });
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
        title: widget.title,
        withLeading: true,
        rightWidgets: _buildRightWidgets(),
        child: Column(
          children: [
            _buildAudioFormats(),
            const Spacer(),
            PlatformAudioRecorder(
              onStop: (String filename) {
                if (mounted) {
                  DialogUtil.info(context,
                      content: 'record audio filename:$filename');
                }
              },
              audioRecorderController: widget.audioRecorderController,
            ),
            const Spacer(),
          ],
        ));
  }
}
