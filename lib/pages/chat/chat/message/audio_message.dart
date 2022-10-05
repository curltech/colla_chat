import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

///消息体：声音消息
class AudioMessage extends StatelessWidget {
  final String thumbnail;
  final String content;
  final bool isMyself;

  const AudioMessage(
      {Key? key,
      required this.content,
      required this.isMyself,
      required this.thumbnail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: ImageWidget(
        image: thumbnail,
      ),
    );
  }
}
