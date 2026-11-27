import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///消息体：加群成员消息
class AddGroupMemberMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const AddGroupMemberMessage(
      {super.key, required this.content, required this.isMyself});

  @override
  Widget build(BuildContext context) {
    List<dynamic> maps = JsonUtil.toJson(content);
    List<String> members = [];
    if (maps.isNotEmpty) {
      for (var map in maps) {
        GroupMember groupMember = GroupMember.fromJson(map);
        var member = groupMember.memberAlias;
        member ??= '';
        members.add(member);
      }
    }
    Widget prefix = IconButton(
        tooltip: AppLocalizations.t('Add group member'),
        onPressed: null,
        icon: Icon(
          Icons.person_add,
          color: myself.primary,
        ));
    var tileData = DataTile(
      prefix: prefix,
      title: 'Add group member',
      subtitle: members.toString(),
      dense: true,
    );
    return CommonMessage(tileData: tileData);
  }
}
