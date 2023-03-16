import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';

///消息体：图片消息
class ImageMessage extends StatelessWidget {
  final String? image;
  final String messageId;
  final String? title;
  final bool isMyself;
  final bool fullScreen;

  const ImageMessage({
    Key? key,
    this.image,
    required this.messageId,
    required this.isMyself,
    this.title,
    this.fullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double? width;
    double? height;
    if (!fullScreen) {
      width = AppImageSize.maxSize;
      height = AppImageSize.maxSize;
    }
    var imageWidget = FutureBuilder(
        future: messageAttachmentService.getDecryptFilename(messageId, title),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (image != null) {
            return ImageUtil.buildImageWidget(
              image: image,
              width: width,
              height: height,
            );
          }
          if (snapshot.hasData) {
            var filename = snapshot.data;
            if (filename == null) {
              return Container();
            }
            return ImageUtil.buildImageWidget(
              image: filename,
              width: width,
              height: height,
            );
          } else {
            return ImageUtil.buildImageWidget();
          }
        });
    return imageWidget;
  }
}
