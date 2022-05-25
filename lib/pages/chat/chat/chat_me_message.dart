import 'package:flutter/material.dart';

import '../websocket_provider.dart';

class ChatMeMessage extends StatefulWidget {
  final ChatMessage message;

  const ChatMeMessage({Key? key, required this.message}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChatMeMessageState();
  }
}

class _ChatMeMessageState extends State<ChatMeMessage> {
  bool isMe = false;
  late String peerId;
  late String message;
  late String createTime;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 10.0),
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
                      createTime,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 5.0),
                      child: Text(message),
                    )
                  ]),
              Container(
                  margin: EdgeInsets.only(left: 16.0),
                  child: CircleAvatar(
                    child: Text('Me'),
                  ))
            ]));
  }
}
