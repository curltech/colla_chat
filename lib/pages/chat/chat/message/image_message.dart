import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';

///消息体：图片消息
class ImageMessage extends StatelessWidget {
  final String? image;
  final String mimeType;
  final String messageId;
  final bool isMyself;

  const ImageMessage(
      {Key? key,
      this.image,
      required this.messageId,
      required this.isMyself,
      required this.mimeType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var imageWidget = FutureBuilder(
        future: messageAttachmentService.getFilename(messageId),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          var filename = snapshot.data;
          if (filename == null) {
            return Container();
          }
          return InkWell(
            onTap: () {},
            child: ImageUtil.buildImageWidget(
              image:filename,
              width: 64,
              height: 64
            ),
          );
        });
    return imageWidget;
  }
}
