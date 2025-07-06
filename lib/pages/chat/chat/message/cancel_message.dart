import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

///消息体：撤销消息
class CancelMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const CancelMessage(
      {super.key, required this.content, required this.isMyself});

  @override
  Widget build(BuildContext context) {
    Widget leading = Icon(
      Icons.cancel,
      color: myself.primary,
    );
    Widget tile = Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          leading,
          const SizedBox(
            width: 5,
          ),
          Expanded(
              child: AutoSizeText(
                  '${AppLocalizations.t('Message')}:$content ${AppLocalizations.t('was canceled')}')),
        ]),
      ),
    );
    return CommonMessage(child: tile);
  }
}
