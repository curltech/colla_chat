import 'package:colla_chat/widgets/media/platform_media_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player_util.dart';
import 'package:flutter/material.dart';

class PlatformMediaPlayer extends StatefulWidget {
  final AbstractMediaPlayerController controller;

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
      this.showVolume = true,
      this.showSpeed = false,
      required this.controller,
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
    return PlatformMediaPlayerUtil.buildMediaPlayer(
      context,
      widget.controller,
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
