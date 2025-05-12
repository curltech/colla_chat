import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media/video/mediakit_video_player.dart';
import 'package:flutter/material.dart';

///消息体：视频消息
class VideoMessage extends StatefulWidget {
  final int id;
  final String? thumbnail;
  final String messageId;
  final String? title;
  final bool isMyself;
  final bool fullScreen;

  const VideoMessage({
    super.key,
    required this.id,
    required this.messageId,
    required this.isMyself,
    this.thumbnail,
    this.title,
    this.fullScreen = false,
  });

  @override
  State<StatefulWidget> createState() => _VideoMessageState();
}

class _VideoMessageState extends State<VideoMessage> {
  ///视频消息中用于播放视频的控制器和播放器
  final MediaKitVideoPlayerController videoMessagePlayerController =
      MediaKitVideoPlayerController(PlaylistController());
  late final PlatformMediaPlayer videoMessagePlayer;
  ValueNotifier<String?> filename = ValueNotifier<String?>(null);

  @override
  void initState() {
    if (widget.fullScreen) {
      messageAttachmentService
          .getDecryptFilename(widget.messageId, widget.title)
          .then((filename) {
        this.filename.value = filename;
      });
    }
    videoMessagePlayerController.autoPlay = true;
    videoMessagePlayer = PlatformMediaPlayer(
      key: UniqueKey(),
      mediaPlayerController: videoMessagePlayerController,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fullScreen) {
      Widget prefix = IconButton(
          onPressed: null,
          icon: Icon(
            Icons.video_call_outlined,
            color: myself.primary,
          ));
      if (widget.thumbnail != null) {
        prefix = ImageUtil.buildImageWidget(
          imageContent: widget.thumbnail,
        );
      }
      var tileData = TileData(
        prefix: prefix,
        title: widget.title!,
      );

      return CommonMessage(
        tileData: tileData,
      );
    }
    var videoPlayer = ValueListenableBuilder<String?>(
        valueListenable: filename,
        builder: (context, filename, child) {
          if (filename != null) {
            videoMessagePlayerController.playlistController.clear();
            videoMessagePlayerController.playlistController
                .addMediaFiles(filenames: [filename]);
            return videoMessagePlayer;
          }
          return nilBox;
        });
    return videoPlayer;
  }

  @override
  void dispose() {
    videoMessagePlayerController.close();
    super.dispose();
  }
}
