import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/media/platform_media_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/video/platform_flick_video_player.dart';
import 'package:colla_chat/widgets/media/video/windows_vlc_video_player.dart';
import 'package:flutter/material.dart';

///平台标准的video-player的实现，移动采用flick，桌面采用vlc
class PlatformVideoPlayer extends StatefulWidget {
  late final AbstractMediaPlayerController controller;

  //自定义简单控制器模式
  final bool showVolume;
  final bool showSpeed;

  //是否显示原生的控制器
  final bool showControls;

  //是否显示播放列表和媒体视图
  final bool showPlaylist;
  final bool showMediaView;

  final Color? color;
  final double? height;
  final double? width;
  final String? filename;
  final List<int>? data;

  PlatformVideoPlayer(
      {Key? key,
      AbstractMediaPlayerController? controller,
      this.showVolume = true,
      this.showSpeed = false,
      this.showControls = true,
      this.showPlaylist = true,
      this.showMediaView = true,
      this.color,
      this.width,
      this.height,
      this.filename,
      this.data})
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
    if (widget.filename != null || widget.data != null) {
      widget.controller.add(filename: widget.filename, data: widget.data);
    }
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
        showVolume: widget.showVolume,
        showSpeed: widget.showSpeed,
        showControls: widget.showControls,
        showPlaylist: widget.showPlaylist,
        showMediaView: widget.showMediaView,
      );
      return player;
    } else {
      var player = PlatformMediaPlayer(
        controller: widget.controller,
        showVolume: widget.showVolume,
        showSpeed: widget.showSpeed,
        showControls: widget.showControls,
        showPlaylist: widget.showPlaylist,
        showMediaView: widget.showMediaView,
      );
      return player;
    }
  }
}
