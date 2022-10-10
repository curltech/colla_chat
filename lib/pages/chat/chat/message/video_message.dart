import 'package:colla_chat/widgets/media/video/platform_video_player.dart';
import 'package:flutter/material.dart';

///消息体：视频消息
class VideoMessage extends StatelessWidget {
  final String? thumbnail;
  final List<int> data;
  final bool isMyself;

  const VideoMessage(
      {Key? key, required this.data, required this.isMyself, this.thumbnail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformVideoPlayer(
        showControls: true, showPlaylist: false, data: data);
  }
}
