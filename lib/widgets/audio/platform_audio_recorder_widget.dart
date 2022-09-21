import 'package:colla_chat/widgets/audio/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///平台标准的video-player的实现，移动采用flick，桌面采用vlc
class PlatformAudioRecorderWidget extends StatefulWidget with TileDataMixin {
  late final PlatformAudioRecorderController controller;

  PlatformAudioRecorderWidget(
      {Key? key, PlatformAudioRecorderController? controller})
      : super(key: key) {
    controller = controller ?? PlatformAudioRecorderController();
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
