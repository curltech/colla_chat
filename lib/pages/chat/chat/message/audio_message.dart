import 'package:colla_chat/widgets/media/video/platform_video_player.dart';
import 'package:flutter/material.dart';

///消息体：声音消息
class AudioMessage extends StatelessWidget {
  final List<int> data;
  final bool isMyself;

  const AudioMessage({
    Key? key,
    required this.data,
    required this.isMyself,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var videoPlayer = PlatformVideoPlayer(
        showControls: false,
        showPlaylist: false,
        showMediaView: false,
        showVolume: true,
        showSpeed: false,
        data: data);
    return SizedBox(height: 80, child: Card(elevation: 0, child: videoPlayer));
  }
}
