import 'package:colla_chat/widgets/audio/platform_audio_player.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///平台标准的video-player的实现，移动采用flick，桌面采用vlc
class PlatformAudioPlayerWidget extends StatefulWidget with TileDataMixin {
  late final PlatformAudioPlayerController controller;

  PlatformAudioPlayerWidget(
      {Key? key, PlatformAudioPlayerController? controller})
      : super(key: key) {
    this.controller = controller ?? PlatformAudioPlayerController();
  }

  @override
  State createState() => _PlatformAudioPlayerWidgetState();

  @override
  String get routeName => 'audio_player';

  @override
  Icon get icon => const Icon(Icons.audiotrack);

  @override
  String get title => 'Audio Player';

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
      title: const Text('Audio Player'),
      withLeading: true,
      child: PlatformAudioPlayer(
        controller: widget.controller,
      ),
    );
  }
}
