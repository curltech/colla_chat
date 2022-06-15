import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';

/// 别人发送给我的消息组件，展示在左边
class ChatOtherMessage extends StatefulWidget {
  final ChatMessage message;

  const ChatOtherMessage({Key? key, required this.message}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChatOtherMessageState();
  }
}

class _ChatOtherMessageState extends State<ChatOtherMessage> {
  bool isMe = false;
  late String userName;
  late String message;
  late String createTime;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  margin: EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    child: Text(userName),
                  )),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      createTime,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 5.0),
                      child: Text(message),
                    )
                  ]),
            ]));
  }
}
