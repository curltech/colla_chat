import 'package:flutter/material.dart';

///消息体：文件消息
class FileMessage extends StatelessWidget {
  final String title;
  final String mimeType;
  final List<int> data;
  final bool isMyself;

  const FileMessage(
      {Key? key,
      required this.data,
      required this.isMyself,
      required this.title,
      required this.mimeType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      softWrap: true,
    );
  }
}
