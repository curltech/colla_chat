import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/video/platform_video_player.dart';
import 'package:flutter/material.dart';

///平台标准的video-player的实现，移动采用flick，桌面采用vlc
class PlatformAudioPlayerWidget extends StatefulWidget with TileDataMixin {
  late final PlatformVideoPlayerController controller;

  PlatformAudioPlayerWidget(
      {Key? key, PlatformVideoPlayerController? controller})
      : super(key: key) {
    controller = controller ?? PlatformVideoPlayerController();
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
      title: const Text('Video Player'),
      withLeading: true,
      child: PlatformVideoPlayer(
        controller: widget.controller,
      ),
    );
  }
}
