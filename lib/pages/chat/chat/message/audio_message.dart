import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:flutter/material.dart';

///消息体：声音消息
class AudioMessage extends StatelessWidget {
  final int id;
  final String messageId;
  final String? title;
  final bool isMyself;
  final bool fullScreen;

  const AudioMessage({
    Key? key,
    required this.id,
    required this.messageId,
    required this.isMyself,
    this.title,
    this.fullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!fullScreen) {
      Widget prefix = Icon(
        Icons.multitrack_audio,
        color: myself.primary,
      );
      prefix = IconButton(onPressed: null, icon: prefix);
      var tileData = TileData(
        prefix: prefix,
        title: title!,
      );

      return CommonMessage(
        tileData: tileData,
      );
    }
    var audioPlayer = FutureBuilder(
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
    return audioPlayer;
  }
}
