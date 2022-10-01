import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/media/platform_media_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/video/platform_flick_video_player.dart';
import 'package:colla_chat/widgets/media/video/windows_vlc_video_player.dart';
import 'package:flutter/material.dart';

///平台标准的video-player的实现，移动采用flick，桌面采用vlc
class PlatformVideoPlayer extends StatefulWidget {
  late final AbstractMediaPlayerController controller;

  PlatformVideoPlayer({Key? key, AbstractMediaPlayerController? controller})
      : super(key: key) {
    if (controller == null) {
      if (platformParams.windows ||
          platformParams.macos ||
          platformParams.linux) {
        this.controller = VlcVideoPlayerController();
      } else {
        this.controller = FlickVideoPlayerController();
      }
    }
  }

  @override
  State createState() => _PlatformVideoPlayerState();
}

class _PlatformVideoPlayerState extends State<PlatformVideoPlayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller is VlcVideoPlayerController) {
      var player = PlatformVlcVideoPlayer(
        controller: widget.controller as VlcVideoPlayerController,
      );
      return player;
    } else {
      var player = PlatformMediaPlayer(controller: widget.controller);
      return player;
    }
  }
}
