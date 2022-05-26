import 'package:flutter/material.dart';

import 'message_data.dart';
import 'message_item.dart';

class MessagePage extends StatefulWidget {
  final String title;

  const MessagePage({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MessagePageState();
  }
}

class _MessagePageState extends State<MessagePage> {
  late final List<MessageData> messages;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView.builder(
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        return MessageItem();
      },
    ));
  }
}
