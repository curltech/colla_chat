import 'package:flutter/material.dart';

import 'message_data.dart';

class MessageItem extends StatefulWidget {
  const MessageItem({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MessageItemState();
  }
}

class _MessageItemState extends State<MessageItem> {
  late final MessageData message;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(width: 0.5, color: Colors.cyan)),
      ),
      height: 64.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 13.0, right: 13.0),
            child: Image.network(message.avatar, width: 48.0, height: 48.0),
          ),
          Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    message.title,
                    style: TextStyle(fontSize: 16.0, color: Colors.grey),
                    maxLines: 1,
                  ),
                  Padding(padding: EdgeInsets.only(top: 8.0)),
                  Text(
                    message.subTitle,
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ]),
          ),
          Container(
              alignment: AlignmentDirectional.topStart,
              margin: EdgeInsets.only(right: 12.0, top: 12.0),
              child: Text(
                message.messageTime.toIso8601String(),
                style: TextStyle(fontSize: 14.0, color: Colors.grey),
              ))
        ],
      ),
    );
  }
}
