import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
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
    if (subMessageType == ChatMessageSubType.addGroup) {
      Group group = Group.fromJson(JsonUtil.toJson(content!));
      var tileData = TileData(
        prefix: IconButton(
          icon: Icon(
            Icons.group_add,
            color: primary,
          ),
          iconSize: AppIconSize.mdSize,
          onPressed: () async {
            //同意加入群，向群的所有成员告知自己加入
            // GroupMember? member = await groupMemberService.findOneByGroupId(
            //     group.peerId, myself.peerId!);
            // if (member != null) {
            //   await groupService.addGroupMember(group.peerId, [member]);
            // }
          },
        ),
        title: group.name,
        dense: false,
      );
      actionWidget = DataListTile(tileData: tileData);
    }
    if (subMessageType == ChatMessageSubType.dismissGroup) {
      Group group = Group.fromJson(JsonUtil.toJson(content!));
      var tileData = TileData(
        prefix: IconButton(
          icon: Icon(
            Icons.group_off,
            color: primary,
          ),
          iconSize: AppIconSize.mdSize,
          onPressed: () {},
        ),
        title: group.name,
        dense: false,
      );
      actionWidget = DataListTile(tileData: tileData);
    }
    if (subMessageType == ChatMessageSubType.modifyGroup) {
      Group group = Group.fromJson(JsonUtil.toJson(content!));
      var tileData = TileData(
        prefix: IconButton(
          icon: Icon(
            Icons.update,
            color: primary,
          ),
          iconSize: AppIconSize.mdSize,
          onPressed: () {},
        ),
        title: group.name,
        dense: false,
      );
      actionWidget = DataListTile(tileData: tileData);
    }
    if (subMessageType == ChatMessageSubType.addGroupMember) {
      List<dynamic> maps = JsonUtil.toJson(content!);
      List<String> members = [];
      if (maps.isNotEmpty) {
        for (var map in maps) {
          GroupMember groupMember = GroupMember.fromJson(map);
          var member = groupMember.memberAlias!;
          members.add(member);
        }
      }
      var tileData = TileData(
        prefix: IconButton(
          icon: Icon(
            Icons.person_add,
            color: primary,
          ),
          iconSize: AppIconSize.mdSize,
          onPressed: () {},
        ),
        title: 'Add group member',
        subtitle: members.toString(),
        dense: false,
      );
      actionWidget = DataListTile(tileData: tileData);
    }
    if (subMessageType == ChatMessageSubType.removeGroupMember) {
      List<dynamic> maps = JsonUtil.toJson(content!);
      List<String> members = [];
      if (maps.isNotEmpty) {
        for (var map in maps) {
          GroupMember groupMember = GroupMember.fromJson(map);
          var member = groupMember.memberAlias!;
          members.add(member);
        }
      }
      var tileData = TileData(
        prefix: IconButton(
          icon: Icon(
            Icons.group_remove,
            color: primary,
          ),
          iconSize: AppIconSize.mdSize,
          onPressed: () {},
        ),
        title: 'Remove group member',
        subtitle: members.toString(),
        dense: false,
      );
      actionWidget = DataListTile(tileData: tileData);
    }

    return Card(elevation: 0, child: actionWidget);
  }
}
