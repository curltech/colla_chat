
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';

///消息体：定位消息
class LocationMessage extends StatelessWidget {
  final String thumbnail;
  final String content;
  final bool isMyself;

  const LocationMessage(
      {Key? key,
      required this.content,
      required this.isMyself,
      required this.thumbnail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: ImageUtil.buildImageWidget(
        image:thumbnail,
      ),
    );
  }
}
