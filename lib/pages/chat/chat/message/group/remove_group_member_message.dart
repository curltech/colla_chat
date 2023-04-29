import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///消息体：移除群成员消息
class RemoveGroupMemberMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const RemoveGroupMemberMessage(
      {Key? key, required this.content, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color primary = myself.primary;
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
    Widget actionWidget = DataListTile(tileData: tileData);
    Widget tile = Center(
      child: actionWidget,
    );

    return Card(elevation: 0, child: tile);
  }
}
