import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

///消息体：扩展文本
class ExtendedTextMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const ExtendedTextMessage(
      {Key? key, required this.content, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtendedText(
      content,
      style: TextStyle(
        color: isMyself ? Colors.white : Colors.black,
        //fontSize: 16.0,
      ),
    );
  }
}
