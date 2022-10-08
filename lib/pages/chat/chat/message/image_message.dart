import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

///消息体：图片消息
class ImageMessage extends StatelessWidget {
  final String mimeType;
  final String image;
  final bool isMyself;

  const ImageMessage(
      {Key? key,
      required this.image,
      required this.isMyself,
      required this.mimeType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: ImageWidget(
        image: image,
      ),
    );
  }
}
