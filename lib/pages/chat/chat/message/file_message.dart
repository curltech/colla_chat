import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

///消息体：文件消息
class FileMessage extends StatelessWidget {
  final String thumbnail;
  final String content;
  final bool isMyself;

  const FileMessage(
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
