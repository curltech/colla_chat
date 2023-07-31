import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
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
    List<dynamic> maps = JsonUtil.toJson(content);
    List<String> members = [];
    if (maps.isNotEmpty) {
      for (var map in maps) {
        GroupMember groupMember = GroupMember.fromJson(map);
        var member = groupMember.memberAlias!;
        members.add(member);
      }
    }
    Widget prefix = IconButton(
        tooltip: AppLocalizations.t('Remove group member'),
        onPressed: null,
        icon: Icon(
          Icons.person_remove,
          color: myself.primary,
        ));
    var tileData = TileData(
      prefix: prefix,
      title: 'Remove group member',
      subtitle: members.toString(),
      dense: true,
    );
    return CommonMessage(tileData: tileData);
  }
}
