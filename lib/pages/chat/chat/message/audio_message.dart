import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///消息体：声音消息
class AudioMessage extends StatelessWidget {
  final int id;
  final String messageId;
  final String? title;
  final bool isMyself;

  const AudioMessage({
    Key? key,
    required this.id,
    required this.messageId,
    required this.isMyself,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var audioPlayer = FutureBuilder(
        future: messageAttachmentService.getFilename(messageId, title),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (snapshot.hasData) {
            var filename = snapshot.data;
            if (filename == null) {
              return Container();
            }
            return PlatformMediaPlayer(
              showControls: false,
              showPlaylist: false,
              showMediaView: false,
              filename: filename,
              mediaPlayerType: MediaPlayerType.webview,
            );
          }
          return Container();
        });
    return Column(children: [Text(title ?? ''), Expanded(child: audioPlayer)]);
  }
}
