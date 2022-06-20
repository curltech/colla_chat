import 'package:colla_chat/provider/linkman_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/common/data_listview.dart';

final Map<TileData, List<TileData>> mockTileData = {
  TileData(title: '未知'): [
    TileData(
        icon: const Icon(Icons.collections),
        title: '收藏',
        routeName: '/chat/collection'),
    TileData(
        icon: const Icon(Icons.settings),
        title: '设置',
        routeName: '/chat/setting'),
  ]
};

//好友页面
class LinkmanWidget extends StatelessWidget {
  const LinkmanWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var linkmen = Provider.of<LinkmanProvider>(context).linkmen;
    List<TileData> tileData = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var tile = TileData(
            avatar: linkman.avatar,
            title: linkman.name,
            subtitle: linkman.peerId,
            routeName: '/chat/setting');
        tileData.add(tile);
      }
    }
    Map<TileData, List<TileData>> linkmanTileData = {
      TileData(title: 'linkmen'): tileData
    };
    var body = DataListView(tileData: linkmanTileData);
    return Container(
      //列表
      child: body,
    );
  }
}
