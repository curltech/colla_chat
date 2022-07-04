import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';

/// 别人发送给我的消息组件，展示在左边
class ChatOtherMessage extends StatelessWidget {
  final ChatMessage message;

  const ChatOtherMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    child: Text(message.senderName ?? ''),
                  )),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      message.sendTime ?? '',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: Text(message.content),
                    )
                  ]),
            ]));
  }
}
