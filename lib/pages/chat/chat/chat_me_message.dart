import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';

/// 我发送的消息展示组件，展示在右边
class ChatMeMessage extends StatelessWidget {
  final ChatMessage message;

  const ChatMeMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Container(),
              ),
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
              Container(
                  margin: const EdgeInsets.only(left: 16.0),
                  child: const CircleAvatar(
                    child: Text('Me'),
                  ))
            ]));
  }
}
