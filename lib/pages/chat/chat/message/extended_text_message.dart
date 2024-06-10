import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/url_util.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:colla_chat/widgets/special_text/link_text.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

///消息体：扩展文本
class ExtendedTextMessage extends StatelessWidget {
  final String content;
  final bool isMyself;
  final bool fullScreen;
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

  ExtendedTextMessage(
      {super.key,
      required this.content,
      required this.isMyself,
      this.fullScreen = false});

  Widget _buildMessageWidget(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(5),
        child: ExtendedText(
          content,
          key: UniqueKey(),
          style: TextStyle(
            color: isMyself ? Colors.white : Colors.black,
            //fontSize: 16.0,
          ),
          specialTextSpanBuilder: customSpecialTextSpanBuilder,
          onSpecialTextTap: (dynamic value) {
            String val = value.toString();
            if (val.startsWith(LinkText.flag) && val.endsWith(LinkText.flag)) {
              val = val.substring(1, val.length - 1);
              bool valid = value.startsWith('http://') ||
                  value.startsWith('https://') ||
                  value.startsWith('mailto:') ||
                  value.startsWith('tel:') ||
                  value.startsWith('sms:') ||
                  value.startsWith('file:');
              if (!valid) {
                final int index = value.indexOf('@');
                final int index1 = value.indexOf('.');
                valid = index > 0 && index1 > index;
                if (valid) {
                  val = 'mailto:$val';
                }
              }

              try {
                UrlUtil.launch(val).then((bool success) {
                  if (!success) {
                    DialogUtil.error(context, content: 'URI launch fail');
                  }
                });
              } catch (e) {
                DialogUtil.error(context, content: 'URI launch fail');
              }
            }
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return _buildMessageWidget(context);
  }
}
