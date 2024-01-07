import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
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
  final bool isFriend;
  final String? title;

  const RequestAddFriendMessage(
      {super.key,
      required this.senderPeerId,
      required this.isMyself,
      required this.isFriend,
      this.title});

  @override
  Widget build(BuildContext context) {
    Widget prefix = IconButton(
      icon: Icon(
        Icons.person_add,
        color: isMyself || isFriend ? myself.secondary : myself.primary,
      ),
      iconSize: AppIconSize.mdSize,
      onPressed: isMyself || isFriend
          ? null
          : () async {
              bool? confirm = await DialogUtil.confirm(context,
                  content: AppLocalizations.t('Do you add all as friend?'));
              if (confirm != null && confirm) {
                await linkmanService.update(
                    {'linkmanStatus': LinkmanStatus.F.name},
                    where: 'peerId=?',
                    whereArgs: [senderPeerId]);
              }
            },
    );
    var tileData = TileData(
      prefix: prefix,
      title: 'Request add friend',
      subtitle: title,
      dense: true,
    );

    return CommonMessage(tileData: tileData);
  }
}
