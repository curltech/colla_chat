import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:flutter/material.dart';

///视频消息中用于播放视频的控制器和播放器
final OriginVideoPlayerController videoMessagePlayerController =
    OriginVideoPlayerController();
final PlatformMediaPlayer videoMessagePlayer = PlatformMediaPlayer(
  key: UniqueKey(),
  showPlaylist: false,
  mediaPlayerController: videoMessagePlayerController,
);

///消息体：视频消息
class VideoMessage extends StatelessWidget {
  final int id;
  final String? thumbnail;
  final String messageId;
  final String? title;
  final bool isMyself;
  final bool fullScreen;

  const VideoMessage({
    Key? key,
    required this.id,
    required this.messageId,
    required this.isMyself,
    this.thumbnail,
    this.title,
    this.fullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!fullScreen) {
      Widget prefix = Icon(
        Icons.video_call_outlined,
        color: myself.primary,
      );
      prefix = IconButton(onPressed: null, icon: prefix);
      if (thumbnail != null) {
        prefix = ImageUtil.buildImageWidget(
          image: thumbnail,
        );
      }
      var tileData = TileData(
        prefix: prefix,
        title: title!,
      );

      return CommonMessage(
        tileData: tileData,
      );
    }
    var videoPlayer = FutureBuilder(
        future: messageAttachmentService.getDecryptFilename(messageId, title),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (snapshot.hasData) {
            var filename = snapshot.data;
            if (filename == null) {
              return Container();
            }
            videoMessagePlayerController.clear();
            videoMessagePlayerController.addAll(filenames: [filename]);
            return videoMessagePlayer;
          }
          return Container();
        });
    return videoPlayer;
  }
}
