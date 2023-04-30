import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///消息体：改变群消息
class ModifyGroupMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const ModifyGroupMessage(
      {Key? key, required this.content, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color primary = myself.primary;
    Icon icon = Icon(
      Icons.update,
      color: primary,
    );
    Widget prefix = IconButton(
      icon: icon,
      iconSize: AppIconSize.mdSize,
      onPressed: () {},
    );
    Group group = Group.fromJson(JsonUtil.toJson(content!));
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
