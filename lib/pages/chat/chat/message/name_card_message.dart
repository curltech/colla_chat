import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///消息体：名片消息，content是json字符串
class NameCardMessage extends StatelessWidget {
  final String content;
  final bool isMyself;
  final bool fullScreen;
  final String? mimeType;

  const NameCardMessage(
      {Key? key,
      required this.content,
      required this.isMyself,
      this.fullScreen = false,
      this.mimeType})
      : super(key: key);

  Widget _buildLinkman(Linkman linkman) {
    String name = linkman.name;
    var peerId = linkman.peerId;
    final List<TileData> linkmanInfoTileData = [
      TileData(
        title: 'Avatar',
        suffix: linkman.avatarImage,
      ),
      TileData(
        title: 'PeerId',
        subtitle: peerId,
      ),
      TileData(
        title: 'Name',
        suffix: name,
      ),
      TileData(
        title: 'Email',
        suffix: linkman.email,
      ),
      TileData(
        title: 'Mobile',
        suffix: linkman.mobile,
      ),
    ];

    return DataListView(tileData: linkmanInfoTileData);
  }

  Widget _buildGroup(Group group) {
    String name = group.name;
    var peerId = group.peerId;
    final List<TileData> groupInfoTileData = [
      TileData(
        title: 'Avatar',
        suffix: group.avatarImage,
      ),
      TileData(
        title: 'PeerId',
        subtitle: peerId,
      ),
      TileData(
        title: 'Name',
        suffix: name,
      ),
      TileData(
        title: 'Email',
        suffix: group.email,
      ),
      TileData(
        title: 'Mobile',
        suffix: group.mobile,
      ),
    ];

    return DataListView(tileData: groupInfoTileData);
  }

  @override
  Widget build(BuildContext context) {
    String? peerId;
    String? name;
    String? avatar;
    Widget? prefix;
    Map<String, dynamic> map = JsonUtil.toJson(content);
    if (mimeType == PartyType.linkman.name) {
      Linkman linkman = Linkman.fromJson(map);

      peerId = linkman.peerId;
      name = linkman.name;
      avatar = linkman.avatar;
      prefix = ImageUtil.buildImageWidget(
          image: avatar, isRadius: true, radius: 2.0);
      linkman.avatarImage = prefix;
      if (fullScreen) {
        return _buildLinkman(linkman);
      }
    }
    if (mimeType == PartyType.group.name) {
      Group group = Group.fromJson(map);
      peerId = group.peerId;
      name = group.name;
      avatar = group.avatar;
      if (avatar != null) {
        prefix = ImageUtil.buildImageWidget(
            image: avatar, isRadius: true, radius: 2.0);
      } else {
        prefix = Icon(
          Icons.group_outlined,
          color: myself.primary,
        );
      }
      group.avatarImage = prefix;
      if (fullScreen) {
        return _buildGroup(group);
      }
    }
    prefix = IconButton(onPressed: null, icon: prefix!);
    var tileData = TileData(prefix: prefix, title: name!, subtitle: peerId);

    return CommonMessage(tileData: tileData);
  }
}
