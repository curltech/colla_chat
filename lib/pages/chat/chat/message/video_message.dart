import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///消息体：视频消息
class VideoMessage extends StatelessWidget {
  final int id;
  final String? thumbnail;
  final String messageId;
  final bool isMyself;

  const VideoMessage(
      {Key? key,
      required this.id,
      required this.messageId,
      required this.isMyself,
      this.thumbnail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var videoPlayer = FutureBuilder(
        future: messageAttachmentService.getFilename(messageId),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          var filename = snapshot.data;
          if (filename == null) {
            return Container();
          }
          return PlatformMediaPlayer(
            showControls: true,
            showPlaylist: false,
            filename: filename,
            mediaPlayerType: MediaPlayerType.flick,
          );
        });
    return SizedBox(height: 80, child: Card(elevation: 0, child: videoPlayer));
  }
}
