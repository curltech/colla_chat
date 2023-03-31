import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
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
    _buildMyselfPeerTileData();
  }

  Future<void> _buildMyselfPeerTileData() async {
    List<MyselfPeer> myselfPeers = await myselfPeerService.findAll();
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
