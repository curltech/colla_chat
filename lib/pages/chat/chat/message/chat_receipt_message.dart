import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

///消息体：回复消息
class ChatReceiptMessage extends StatelessWidget {
  final ChatMessage chatMessage;
  final bool isMyself;

  const ChatReceiptMessage(
      {super.key, required this.chatMessage, required this.isMyself});

  @override
  Widget build(BuildContext context) {
    var title = AppLocalizations.t(chatMessage.title ?? '');
    var content = chatMessageService.recoverContent(chatMessage.content!);
    var receiverPeerId = chatMessage.receiverPeerId;
    var receiverName = chatMessage.receiverName;
    var groupName = chatMessage.groupName ?? '';
    var groupType = AppLocalizations.t(chatMessage.groupType ?? '');
    Widget leading = Icon(
      Icons.receipt_long,
      color: myself.primary,
    );
    Widget tile = InkWell(
      onTap: () {},
      child: ListTile(
        leading: leading,
        title: CommonAutoSizeText(
            title + groupType + AppLocalizations.t('receipt')),
        subtitle: CommonAutoSizeText(
            '$receiverName\n$groupName\n${AppLocalizations.t(content)}'),
        //dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 5.0),
        horizontalTitleGap: 0,
        minVerticalPadding: 0,
        //minLeadingWidth: 5,
      ),
    );
    return Card(elevation: 0, child: tile);
  }
}
