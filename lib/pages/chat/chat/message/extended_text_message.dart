import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../widgets/special_text/custom_special_text_span_builder.dart';

///消息体：扩展文本
class ExtendedTextMessage extends StatelessWidget {
  final String content;
  final bool isMyself;
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

  ExtendedTextMessage({Key? key, required this.content, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtendedText(
      content,
      style: TextStyle(
        color: isMyself ? Colors.white : Colors.black,
        //fontSize: 16.0,
      ),
      specialTextSpanBuilder: customSpecialTextSpanBuilder,
      onSpecialTextTap: (dynamic value) {
        if (value.toString().startsWith('\$')) {
          launchUrl(
              Uri(scheme: 'https', host: 'github.com', path: 'fluttercandies'));
        } else if (value.toString().startsWith('@')) {
          launchUrl(Uri(
            scheme: 'mailto',
            path: 'zmtzawqlp@live.com',
          ));
        }
      },
    );
  }
}
