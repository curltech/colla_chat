import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/video/platform_video_player_widget.dart';
import 'package:flutter/material.dart';

///平台标准的video-player的实现，移动采用flick，桌面采用vlc
class PlatformVideoPlayer extends StatefulWidget with TileDataMixin {
  late final PlatformVideoPlayerController controller;

  PlatformVideoPlayer({Key? key, PlatformVideoPlayerController? controller})
      : super(key: key) {
    controller = controller ?? PlatformVideoPlayerController();
  }

  @override
  State createState() => _PlatformVideoPlayerState();

  @override
  String get routeName => 'video_player';

  @override
  Icon get icon => const Icon(Icons.perm_media);

  @override
  String get title => 'Video Player';

  @override
  bool get withLeading => true;
}

class _PlatformVideoPlayerState extends State<PlatformVideoPlayer> {
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
      child: PlatformVideoPlayerWidget(
        controller: widget.controller,
      ),
    );
  }
}
