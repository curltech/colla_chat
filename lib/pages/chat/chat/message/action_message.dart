import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:flutter/material.dart';

///消息体：命令消息，由固定文本和icon组成
class ActionMessage extends StatelessWidget {
  final ChatMessageSubType subMessageType;
  final bool isMyself;
  final String? title;
  final String? content;
  final CustomSpecialTextSpanBuilder customSpecialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

  ActionMessage(
      {Key? key,
      required this.isMyself,
      required this.subMessageType,
      this.title,
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
      Group group = Group.fromJson(JsonUtil.toJson(content!));

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
                    group.name,
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
    if (subMessageType == ChatMessageSubType.dismissGroup) {
      var content = chatMessageService.recoverContent(this.content!);
      actionWidget = InkWell(
          onTap: () {},
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(children: [
                Icon(
                  Icons.group_off,
                  color: primary,
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Text(
                    content,
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
    if (subMessageType == ChatMessageSubType.modifyGroup) {
      Group group = Group.fromJson(JsonUtil.toJson(content!));
      actionWidget = InkWell(
          onTap: () {},
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(children: [
                Icon(
                  Icons.update,
                  color: primary,
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Text(
                    group.name,
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
    if (subMessageType == ChatMessageSubType.addGroupMember) {
      List<dynamic> maps = JsonUtil.toJson(content!);
      List<Widget> members = [];
      if (maps.isNotEmpty) {
        for (var map in maps) {
          GroupMember groupMember = GroupMember.fromJson(map);
          var member = Text(
            groupMember.memberAlias!,
            style: const TextStyle(
                //color: isMyself ? Colors.white : Colors.black,
                //fontSize: 16.0,
                ),
            //specialTextSpanBuilder: customSpecialTextSpanBuilder,
          );
          members.add(member);
        }
      }

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: members,
                  ),
                ),
              ])));
    }
    if (subMessageType == ChatMessageSubType.removeGroupMember) {
      List<dynamic> maps = JsonUtil.toJson(content!);
      List<Widget> members = [];
      if (maps.isNotEmpty) {
        for (var map in maps) {
          GroupMember groupMember = GroupMember.fromJson(map);
          var member = Text(
            groupMember.memberAlias!,
            style: const TextStyle(
              //color: isMyself ? Colors.white : Colors.black,
              //fontSize: 16.0,
            ),
            //specialTextSpanBuilder: customSpecialTextSpanBuilder,
          );
          members.add(member);
        }
      }

      actionWidget = InkWell(
          onTap: () {},
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(children: [
                Icon(
                  Icons.group_remove,
                  color: primary,
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: members,
                  ),
                ),
              ])));
    }

    return Card(elevation: 0, child: actionWidget);
  }
}
