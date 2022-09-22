import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/audio/platform_another_audio_recorder.dart';
import 'package:colla_chat/widgets/audio/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///平台标准的video-player的实现，移动采用flick，桌面采用vlc
class PlatformAudioRecorderWidget extends StatefulWidget with TileDataMixin {
  late final AbstractAudioRecorderController controller;

  PlatformAudioRecorderWidget(
      {Key? key, AbstractAudioRecorderController? controller})
      : super(key: key) {
    if (controller == null) {
      if (platformParams.ios || platformParams.android || platformParams.web) {
        this.controller = AnotherAudioRecorderController();
      } else {
        this.controller = PlatformAudioRecorderController();
      }
    } else {
      this.controller = controller;
    }
  }

  @override
  State createState() => _PlatformAudioRecorderWidgetState();

  @override
  String get routeName => 'audio_recorder';

  @override
  Icon get icon => const Icon(Icons.audiotrack);

  @override
  String get title => 'Audio Recorder';

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

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: const Text('Audio Recorder'),
      withLeading: true,
      child: PlatformAudioRecorder(
        controller: widget.controller,
        onStop: (String filename) {},
      ),
    );
  }
}
