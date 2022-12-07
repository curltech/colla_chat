import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/special_text/custom_special_text_span_builder.dart';

///消息体：命令消息，由固定文本和icon组成
class ActionMessage extends StatelessWidget {
  final ChatMessageSubType subMessageType;
  final bool isMyself;
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

  ActionMessage(
      {Key? key, required this.isMyself, required this.subMessageType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (subMessageType == ChatMessageSubType.videoChat) {
      Color color = appDataProvider.themeData.colorScheme.primary;

      return InkWell(
          onTap: () {},
          child: Row(children: [
            Expanded(
              child: ExtendedText(
                '视频通话邀请',
                key: UniqueKey(),
                style: TextStyle(
                  color: isMyself ? Colors.white : Colors.black,
                  //fontSize: 16.0,
                ),
                specialTextSpanBuilder: customSpecialTextSpanBuilder,
              ),
            ),
            Icon(
              Icons.video_call,
              color: isMyself ? Colors.white : color,
            )
          ]));
    }
    if (subMessageType == ChatMessageSubType.addFriend) {
      Color color = appDataProvider.themeData.colorScheme.primary;

      return InkWell(
          onTap: () {},
          child: Row(children: [
            Expanded(
              child: ExtendedText(
                AppLocalizations.t('Add friend'),
                key: UniqueKey(),
                style: TextStyle(
                  color: isMyself ? Colors.white : Colors.black,
                  //fontSize: 16.0,
                ),
                specialTextSpanBuilder: customSpecialTextSpanBuilder,
              ),
            ),
            Icon(
              Icons.person_add,
              color: isMyself ? Colors.white : color,
            )
          ]));
    }

    return Container();
  }
}
