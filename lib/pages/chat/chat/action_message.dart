import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

import '../../../widgets/special_text/custom_special_text_span_builder.dart';

///消息体：命令消息，由固定文本和icon组成
class ActionMessage extends StatelessWidget {
  final Widget icon;
  final String content;
  final bool isMyself;
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

  ActionMessage(
      {Key? key,
      required this.content,
      required this.isMyself,
      required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {},
        child: Row(children: [
          Expanded(
            child: ExtendedText(
              content,
              style: TextStyle(
                color: isMyself ? Colors.white : Colors.black,
                //fontSize: 16.0,
              ),
              specialTextSpanBuilder: customSpecialTextSpanBuilder,
            ),
          ),
          icon
        ]));
  }
}
