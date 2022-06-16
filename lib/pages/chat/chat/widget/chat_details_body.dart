import 'package:colla_chat/pages/chat/chat/widget/send_message_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../entity/chat/chat.dart';
import 'indicator_page_view.dart';

class ChatDetailsBody extends StatelessWidget {
  final ScrollController sC;
  final List<ChatMessage> chatData;

  ChatDetailsBody({required this.sC, required this.chatData});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: ScrollConfiguration(
        behavior: MyBehavior(),
        child: ListView.builder(
          controller: sC,
          padding: EdgeInsets.all(8.0),
          reverse: true,
          itemBuilder: (context, int index) {
            ChatMessage model = chatData[index];
            return SendMessageView(model);
          },
          itemCount: chatData.length,
          dragStartBehavior: DragStartBehavior.down,
        ),
      ),
    );
  }
}
