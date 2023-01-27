import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:flutter/material.dart';

///消息体：命令消息，由固定文本和icon组成
class ActionMessage extends StatelessWidget {
  final ChatMessageSubType subMessageType;
  final bool isMyself;
  final String? content;
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

  ActionMessage(
      {Key? key,
      required this.isMyself,
      required this.subMessageType,
      this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color primary = myself.primary;
    Widget actionWidget = Container();
    if (subMessageType == ChatMessageSubType.videoChat) {
      actionWidget = InkWell(
          onTap: () {},
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(children: [
                Icon(
                  Icons.video_call,
                  color: primary,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  AppLocalizations.t('Video chat invitation'),
                  key: UniqueKey(),
                  style: const TextStyle(
                      //color: isMyself ? Colors.white : Colors.black,
                      //fontSize: 16.0,
                      ),
                  //specialTextSpanBuilder: customSpecialTextSpanBuilder,
                ),
              ])));
    }
    if (subMessageType == ChatMessageSubType.addFriend) {
      actionWidget = InkWell(
          onTap: () {},
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(children: [
                Icon(
                  Icons.person_add,
                  color: primary,
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.t('Add friend'),
                    key: UniqueKey(),
                    style: const TextStyle(
                        //color: isMyself ? Colors.white : Colors.black,
                        //fontSize: 16.0,
                        ),
                    //specialTextSpanBuilder: customSpecialTextSpanBuilder,
                  ),
                ),
              ])));
    }
    if (subMessageType == ChatMessageSubType.addGroup) {
      actionWidget = InkWell(
          onTap: () {},
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(children: [
                Icon(
                  Icons.group_add,
                  color: primary,
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.t(content!),
                    key: UniqueKey(),
                    style: const TextStyle(
                        //color: isMyself ? Colors.white : Colors.black,
                        //fontSize: 16.0,
                        ),
                    //specialTextSpanBuilder: customSpecialTextSpanBuilder,
                  ),
                ),
              ])));
    }
    if (subMessageType == ChatMessageSubType.dismissGroup) {}
    if (subMessageType == ChatMessageSubType.modifyGroup) {}
    if (subMessageType == ChatMessageSubType.addGroupMember) {}
    if (subMessageType == ChatMessageSubType.removeGroupMember) {}

    return Card(elevation: 0, child: actionWidget);
  }
}
