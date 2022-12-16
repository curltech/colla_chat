import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

///消息体：回复消息
class ChatReceiptMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const ChatReceiptMessage(
      {Key? key, required this.content, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget leading = Icon(
      Icons.receipt,
      color: appDataProvider.themeData.colorScheme.primary,
    );
    Widget tile = Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          leading,
          const SizedBox(
            width: 5,
          ),
          Expanded(child: Text(content)),
        ]),
      ),
    );
    return Card(elevation: 0, child: tile);
  }
}
