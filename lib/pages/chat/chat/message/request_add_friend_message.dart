import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///消息体：请求加好友消息
class RequestAddFriendMessage extends StatelessWidget {
  final String senderPeerId;
  final bool isMyself;

  const RequestAddFriendMessage(
      {Key? key, required this.senderPeerId, required this.isMyself})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color primary = myself.primary;
    Icon icon = Icon(
      Icons.person_add,
      color: primary,
    );
    Widget prefix = isMyself
        ? icon
        : IconButton(
            icon: icon,
            iconSize: AppIconSize.mdSize,
            onPressed: () async {
              bool? confirm = await DialogUtil.confirm(context,
                  content: 'Do you agree to add friend?');
              if (confirm != null && confirm) {
                await linkmanService.update(
                    {'linkmanStatus': LinkmanStatus.friend.name},
                    where: 'peerId=?',
                    whereArgs: [senderPeerId]);
              }
            },
          );
    var tileData = TileData(
      prefix: prefix,
      title: 'Request add friend',
      dense: true,
    );

    return CommonMessage(tileData: tileData);
  }
}
