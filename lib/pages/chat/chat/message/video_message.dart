import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/media/platform_media_player.dart';
import 'package:colla_chat/widgets/media/video/origin_video_player.dart';
import 'package:flutter/material.dart';

///消息体：视频消息
class VideoMessage extends StatefulWidget {
  final int id;
  final String? thumbnail;
  final String messageId;
  final String? title;
  final bool isMyself;
  final bool fullScreen;

  VideoMessage({
    Key? key,
    required this.id,
    required this.messageId,
    required this.isMyself,
    this.thumbnail,
    this.title,
    this.fullScreen = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoMessageState();
}

class _VideoMessageState extends State<VideoMessage> {
  ///视频消息中用于播放视频的控制器和播放器
  final OriginVideoPlayerController videoMessagePlayerController =
      OriginVideoPlayerController();
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
    videoMessagePlayerController.autoplay = true;
    videoMessagePlayer = PlatformMediaPlayer(
      key: UniqueKey(),
      showPlaylist: false,
      mediaPlayerController: videoMessagePlayerController,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fullScreen) {
      Widget prefix = Icon(
        Icons.video_call_outlined,
        color: myself.primary,
      );
      prefix = IconButton(onPressed: null, icon: prefix);
      if (widget.thumbnail != null) {
        prefix = ImageUtil.buildImageWidget(
          image: widget.thumbnail,
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
            videoMessagePlayerController.clear();
            videoMessagePlayerController.addAll(filenames: [filename]);
            return videoMessagePlayer;
          }
          return Container();
        });
    return videoPlayer;
  }

  @override
  void dispose() {
    videoMessagePlayerController.close();
    super.dispose();
  }
}
