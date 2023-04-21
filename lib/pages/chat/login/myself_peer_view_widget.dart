import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/myselfpeer/myself_peer_controller.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///自己的本地账号组件
class MyselfPeerViewWidget extends StatefulWidget {
  const MyselfPeerViewWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyselfPeerViewWidgetState();
}

class _MyselfPeerViewWidgetState extends State<MyselfPeerViewWidget> {
  final ValueNotifier<List<TileData>> tiles = ValueNotifier<List<TileData>>([]);

  @override
  initState() {
    super.initState();
    myselfPeerController.addListener(_update);
    myselfPeerController.init();
  }

  _update() {
    _buildMyselfPeerTileData();
  }

  Future<void> _buildMyselfPeerTileData() async {
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
          return DataListView(tileData: tiles);
        });

    return myselfPeers;
  }
}
