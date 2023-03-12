import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///消息体：视频消息
class VideoMessage extends StatelessWidget {
  final int id;
  final String? thumbnail;
  final String messageId;
  final String? title;
  final bool isMyself;

  const VideoMessage(
      {Key? key,
      required this.id,
      required this.messageId,
      required this.isMyself,
      this.thumbnail,
      this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var videoPlayer = FutureBuilder(
        future: messageAttachmentService.getDecryptFilename(messageId, title),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (snapshot.hasData) {
            var filename = snapshot.data;
            if (filename == null) {
              return Container();
            }
            return PlatformMediaPlayer(
              key: UniqueKey(),
              showPlaylist: false,
              filename: filename,
              videoPlayerType: VideoPlayerType.webview,
            );
          }
          return Container();
        });
    return videoPlayer;
  }
}
