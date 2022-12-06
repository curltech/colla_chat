import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/media/audio/recorder/platform_audio_recorder.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:flutter/material.dart';

///平台标准的video-player的实现，移动采用flick，桌面采用vlc
class PlatformAudioRecorderWidget extends StatefulWidget with TileDataMixin {
  PlatformAudioRecorderWidget(
      {Key? key, AbstractAudioRecorderController? controller})
      : super(key: key);

  @override
  State createState() => _PlatformAudioRecorderWidgetState();

  @override
  String get routeName => 'audio_recorder';

  @override
  Icon get icon => const Icon(Icons.record_voice_over);

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

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: Text(AppLocalizations.t('AudioRecorder')),
      withLeading: true,
      child: PlatformAudioRecorder(
        onStop: (String filename) {},
      ),
    );
  }
}
