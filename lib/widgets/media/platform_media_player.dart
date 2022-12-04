import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player_util.dart';
import 'package:colla_chat/widgets/media/video/dart_vlc_video_player.dart';
import 'package:colla_chat/widgets/media/video/flick_video_player.dart';
import 'package:colla_chat/widgets/media/video/webview_video_player.dart';
import 'package:flutter/material.dart';

enum MediaPlayerType {
  dart_vlc,
  flick,
  webview,
  just,
  bluefire,
  another,
}

///平台的媒体播放器组件
class PlatformMediaPlayer extends StatefulWidget {
  final MediaPlayerType mediaPlayerType;

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

  const PlatformMediaPlayer(
      {Key? key,
      required this.mediaPlayerType,
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
      : super(key: key);

  @override
  State createState() => _PlatformMediaPlayerState();
}

class _PlatformMediaPlayerState extends State<PlatformMediaPlayer> {
  late AbstractMediaPlayerController controller;

  @override
  void initState() {
    super.initState();
    _updateMediaPlayerType();
    controller.addListener(_update);
    if (widget.filename != null || widget.data != null) {
      controller.add(filename: widget.filename, data: widget.data);
    }
  }

  _update() {
    setState(() {});
  }

  _updateMediaPlayerType() {
    switch (widget.mediaPlayerType) {
      case MediaPlayerType.dart_vlc:
        controller = DartVlcVideoPlayerController();
        break;
      case MediaPlayerType.flick:
        controller = FlickVideoPlayerController();
        break;

      case MediaPlayerType.webview:
        controller = WebviewVideoPlayerController();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_update);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformMediaPlayerUtil.buildMediaPlayer(
      context,
      controller,
      showControls: widget.showControls,
      showPlaylist: widget.showPlaylist,
      showMediaView: widget.showMediaView,
      showVolume: widget.showVolume,
      showSpeed: widget.showSpeed,
      color: widget.color,
      height: widget.height,
      width: widget.width,
    );
  }
}
