import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

///消息体：回复消息
class ChatReceiptMessage extends StatelessWidget {
  final ChatMessage chatMessage;
  final bool isMyself;

  const ChatReceiptMessage(
      {Key? key, required this.chatMessage, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var title = chatMessage.title;
    var status = chatMessage.status;
    var receiverName = chatMessage.receiverName;
    Widget leading = Icon(
      Icons.receipt_long,
      color: appDataProvider.themeData.colorScheme.primary,
    );
    Widget tile = Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          leading,
          Text(receiverName!),
          const SizedBox(
            width: 10,
          ),
          Text(AppLocalizations.t(title!)),
          const SizedBox(
            width: 10,
          ),
          Text(AppLocalizations.t(status!)),
        ]),
      ),
    );
    return Card(elevation: 0, child: tile);
  }
}
