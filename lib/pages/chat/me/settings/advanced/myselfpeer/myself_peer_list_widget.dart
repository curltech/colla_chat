import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/myselfpeer/myself_peer_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///自己的本地账号组件
class MyselfPeerListWidget extends StatelessWidget with TileDataMixin {
  const MyselfPeerListWidget({super.key});

  @override
  String get routeName => 'myself_peer';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.account_circle;

  @override
  String get title => 'MyselfPeer';

  

  List<TileData> _buildMyselfPeerTileData() {
    List<TileData> tiles = [];
    List<MyselfPeer> myselfPeers = myselfPeerController.data;
    if (myselfPeers.isNotEmpty) {
      int i = 0;
      for (var myselfPeer in myselfPeers) {
        var tile = TileData(
          selected: myselfPeerController.currentIndex.value == i,
          title: myselfPeer.loginName,
          subtitle: myselfPeer.peerId,
          titleTail: myselfPeer.name,
          prefix: myselfPeer.avatarImage,
        );
        tiles.add(tile);
        i++;
      }
    }

    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    List<TileData> tiles = _buildMyselfPeerTileData();
    var myselfPeers = DataListView(
      itemCount: tiles.length,
      itemBuilder: (BuildContext context, int index) {
        return tiles[index];
      },
      onTap: (int index, String title, {TileData? group, String? subtitle}) {
        myselfPeerController.setCurrentIndex = index;
      },
    );
    var appBarView =
        AppBarView(title: title,helpPath: routeName, withLeading: withLeading, child: myselfPeers);

    return appBarView;
  }
}
