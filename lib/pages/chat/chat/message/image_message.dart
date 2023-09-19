import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:flutter/material.dart';

///消息体：图片消息
class ImageMessage extends StatelessWidget {
  final String? thumbnail;
  final String messageId;
  final String? title;
  final bool isMyself;
  final bool fullScreen;

  const ImageMessage({
    Key? key,
    this.thumbnail,
    required this.messageId,
    required this.isMyself,
    this.title,
    this.fullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double? width;
    double? height;
    Widget imageWidget;
    if (!fullScreen) {
      width = AppImageSize.lgSize;
      height = AppImageSize.lgSize;
      if (thumbnail != null) {
        imageWidget = ImageUtil.buildImageWidget(
          image: thumbnail,
          width: width,
          height: height,
        );

        return CommonMessage(child: imageWidget);
      }
    }

    imageWidget = FutureBuilder(
        future: messageAttachmentService.getDecryptFilename(messageId, title),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (snapshot.hasData) {
            var filename = snapshot.data;
            if (filename != null) {
              return ImageUtil.buildImageWidget(
                image: filename,
                width: width,
                height: height,
              );
            }
          }
          return LoadingUtil.buildCircularLoadingWidget();
        });

    if (!fullScreen) {
      return CommonMessage(child: imageWidget);
    }

    return imageWidget;
  }
}
