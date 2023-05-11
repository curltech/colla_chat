import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/abstract_audio_recorder_controller.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/record_audio_recorder.dart';
import 'package:colla_chat/widgets/media/audio/recorder/waveforms_audio_recorder.dart';
import 'package:flutter/material.dart';

enum MediaRecorderType {
  record,
  another,
  waveform,
}

///平台标准的record的实现
class PlatformAudioRecorderWidget extends StatefulWidget with TileDataMixin {
  AbstractAudioRecorderController audioRecorderController =
      RecordAudioRecorderController();

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
              widget.audioRecorderController = RecordAudioRecorderController();
            });
          } else if (newIndex == 1) {
            setState(() {
              widget.audioRecorderController =
                  WaveformsAudioRecorderController();
            });
          }
        },
        children: const <Widget>[
          Icon(
            Icons.web_outlined,
            color: Colors.white,
          ),
          Icon(
            Icons.video_call_outlined,
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
            const Spacer(),
            PlatformAudioRecorder(
              onStop: (String filename) {
                logger.i('record audio filename:$filename');
              },
              audioRecorderController: widget.audioRecorderController,
            ),
            const Spacer(),
          ],
        ));
  }
}
