import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///消息体：名片消息，content是json字符串
class NameCardMessage extends StatelessWidget {
  final List<Linkman>? linkmen;
  final List<Group>? groups;
  final bool isMyself;
  final bool fullScreen;
  final String? mimeType;

  const NameCardMessage(
      {super.key,
      this.linkmen,
      this.groups,
      required this.isMyself,
      this.fullScreen = false,
      this.mimeType});

  Widget _buildLinkmanWidget(List<Linkman> linkmen) {
    final List<TileData> linkmanInfoTileData = [];
    for (Linkman linkman in linkmen) {
      String name = linkman.name;
      var peerId = linkman.peerId;
      String? avatar = linkman.avatar;
      Widget prefix = ImageUtil.buildImageWidget(
          image: avatar, isRadius: true, radius: 2.0);
      linkmanInfoTileData.add(TileData(
        prefix: prefix,
        title: name,
        subtitle: peerId,
        titleTail: linkman.email,
      ));
    }

    return Container(
        alignment: Alignment.topLeft,
        child: DataListView(
          itemCount: linkmanInfoTileData.length,
          itemBuilder: (BuildContext context, int index) {
            return linkmanInfoTileData[index];
          },
        ));
  }

  Widget _buildGroupWidget(List<Group> groups) {
    final List<TileData> groupInfoTileData = [];
    for (Group group in groups) {
      String name = group.name;
      var peerId = group.peerId;
      Widget prefix;
      String? avatar = group.avatar;
      if (avatar != null) {
        prefix = ImageUtil.buildImageWidget(
            image: avatar, isRadius: true, radius: 2.0);
      } else {
        prefix = Icon(
          Icons.group_outlined,
          color: myself.primary,
        );
      }
      groupInfoTileData.add(TileData(
        prefix: prefix,
        title: name,
        subtitle: peerId,
        titleTail: group.email,
      ));
    }

    return DataListView(
        itemCount: groupInfoTileData.length,
        itemBuilder: (BuildContext context, int index) {
          return groupInfoTileData[index];
        });
  }

  @override
  Widget build(BuildContext context) {
    if (mimeType == PartyType.linkman.name &&
        linkmen != null &&
        linkmen!.isNotEmpty) {
      if (fullScreen) {
        return _buildLinkmanWidget(linkmen!);
      } else {
        Widget prefix = IconButton(
            onPressed: () async {
              for (Linkman linkman in linkmen!) {
                linkman.linkmanStatus = null;
                linkmanService.store(linkman);
              }
              bool? confirm = await DialogUtil.confirm(
                  content: 'Do you add all as friend?');
              if (confirm != null && confirm) {
                for (Linkman linkman in linkmen!) {
                  linkmanService.update({'linkmanStatus': LinkmanStatus.F.name},
                      where: 'peerId=?', whereArgs: [linkman.peerId]);
                }
              }
            },
            tooltip: AppLocalizations.t('Add friend'),
            icon: Icon(
              Icons.person_add,
              color: myself.primary,
            ));
        List<String> names = [];
        for (Linkman linkman in linkmen!) {
          names.add(linkman.name);
        }
        Widget child = Row(children: [
          prefix,
          Expanded(child: CommonAutoSizeText(names.toString()))
        ]);

        return CommonMessage(child: child);
      }
    }
    if (mimeType == PartyType.group.name &&
        groups != null &&
        groups!.isNotEmpty) {
      if (fullScreen) {
        return _buildGroupWidget(groups!);
      } else {
        Widget prefix =
            const IconButton(onPressed: null, icon: Icon(Icons.group_add));
        List<String> names = [];
        for (Group group in groups!) {
          names.add(group.name);
        }
        Widget child = Row(children: [
          prefix,
          Expanded(child: CommonAutoSizeText(names.toString()))
        ]);

        return CommonMessage(child: child);
      }
    }

    return nil;
  }
}
