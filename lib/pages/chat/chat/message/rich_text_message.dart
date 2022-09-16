import 'package:flutter/material.dart';

///消息体：富文本
class RichTextMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const RichTextMessage(
      {Key? key, required this.content, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
          text: content,
          style: TextStyle(
            color: isMyself ? Colors.white : Colors.black,
            //fontSize: 16.0,
          )),
    );
  }
}
