import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:flutter/material.dart';

///消息体：命令消息，由固定文本和icon组成
class ActionMessage extends StatelessWidget {
  final ChatMessageSubType subMessageType;
  final bool isMyself;
  final String? title;
  final String? content;
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

  ActionMessage(
      {Key? key,
      required this.isMyself,
      required this.subMessageType,
      this.title,
      this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color primary = myself.primary;
    Widget actionWidget = Container();

    return Card(elevation: 0, child: actionWidget);
  }
}
