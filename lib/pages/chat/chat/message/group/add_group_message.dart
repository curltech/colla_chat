import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///消息体：加群消息
class AddGroupMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const AddGroupMessage(
      {Key? key, required this.content, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color primary = myself.primary;
    Icon icon = Icon(
      Icons.group_add,
      color: primary,
    );
    Widget prefix = isMyself
        ? icon
        : IconButton(
            icon: icon,
            iconSize: AppIconSize.mdSize,
            onPressed: () async {
              bool? confirm = await DialogUtil.confirm(context,
                  content: 'Do you agree to add group?');
              if (confirm != null && confirm) {
                //同意加入群，向群的所有成员告知自己加入
                // GroupMember? member = await groupMemberService.findOneByGroupId(
                //     group.peerId, myself.peerId!);
                // if (member != null) {
                //   await groupService.addGroupMember(group.peerId, [member]);
                // }
              }
            },
          );
    Group group = Group.fromJson(JsonUtil.toJson(content));
    var tileData = TileData(
      prefix: prefix,
      title: group.name,
      dense: false,
    );
    Widget actionWidget = DataListTile(tileData: tileData);
    Widget tile = Center(
      child: actionWidget,
    );

    return Card(elevation: 0, child: tile);
  }
}
