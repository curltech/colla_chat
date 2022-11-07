import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/media/audio/platform_audio_player.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///平台标准的video-player的实现，移动采用flick，桌面采用vlc
class PlatformAudioPlayerWidget extends StatefulWidget with TileDataMixin {
  const PlatformAudioPlayerWidget({super.key});

  @override
  State createState() => _PlatformAudioPlayerWidgetState();

  @override
  String get routeName => 'audio_player';

  @override
  Icon get icon => const Icon(Icons.audiotrack);

  @override
  String get title => 'AudioPlayer';

  @override
  bool get withLeading => true;
}

class _PlatformAudioPlayerWidgetState extends State<PlatformAudioPlayerWidget> {
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
      title: Text(AppLocalizations.t('AudioPlayer')),
      withLeading: true,
      child: PlatformAudioPlayer(),
    );
  }
}
