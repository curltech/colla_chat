import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';

///消息体：图片消息
class ImageMessage extends StatelessWidget {
  final String? image;
  final String mimeType;
  final String messageId;
  final String? title;
  final bool isMyself;
  final double? width;
  final double? height;

  const ImageMessage({
    Key? key,
    this.image,
    required this.messageId,
    required this.isMyself,
    required this.mimeType,
    this.width,
    this.height, this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var imageWidget = FutureBuilder(
        future: messageAttachmentService.getDecryptFilename(messageId,title),
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
            return ImageUtil.buildImageWidget(
              width: width,
              height: height,
            );
          }
        });
    return imageWidget;
  }
}
