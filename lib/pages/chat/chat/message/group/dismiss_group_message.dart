import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///消息体：解散群消息
class DismissGroupMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const DismissGroupMessage(
      {Key? key, required this.content, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget prefix = IconButton(
        onPressed: null,
        icon:Icon(
      Icons.group_off,
      color: myself.primary,
    ));
    Group group = Group.fromJson(JsonUtil.toJson(content));
    var tileData = TileData(
      prefix: prefix,
      title: group.name,
      dense: true,
    );
    return CommonMessage(tileData: tileData);
  }
}
