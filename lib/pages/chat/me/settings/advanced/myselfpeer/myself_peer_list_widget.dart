import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/myselfpeer/myself_peer_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///自己的本地账号组件
class MyselfPeerListWidget extends StatefulWidget with TileDataMixin {
  const MyselfPeerListWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyselfPeerListWidgetState();

  @override
  String get routeName => 'myself_peer';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.account_circle;

  @override
  String get title => 'MyselfPeer';
}

class _MyselfPeerListWidgetState extends State<MyselfPeerListWidget> {
  final ValueNotifier<List<TileData>> tiles = ValueNotifier<List<TileData>>([]);

  @override
  initState() {
    super.initState();
    myselfPeerController.addListener(_update);
  }

  _update() {
    _buildMyselfPeerTileData();
  }

  void _buildMyselfPeerTileData() {
    List<MyselfPeer> myselfPeers = myselfPeerController.data;
    if (myselfPeers.isNotEmpty) {
      List<TileData> tiles = [];
      for (var myselfPeer in myselfPeers) {
        var tile = TileData(
          title: myselfPeer.loginName,
          subtitle: myselfPeer.peerId,
          titleTail: myselfPeer.name,
          prefix: myselfPeer.avatarImage,
        );
        tiles.add(tile);
      }
      this.tiles.value = tiles;
    }
  }

  @override
  Widget build(BuildContext context) {
    var myselfPeers = ValueListenableBuilder(
        valueListenable: tiles,
        builder: (BuildContext context, List<TileData> tiles, Widget? child) {
          return DataListView(
            tileData: tiles,
            currentIndex: myselfPeerController.currentIndex,
            onTap: (int index, String title,
                {TileData? group, String? subtitle}) {
              myselfPeerController.currentIndex = index;
            },
          );
        });
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: myselfPeers);

    return appBarView;
  }
}
