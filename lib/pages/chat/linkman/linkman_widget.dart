import 'package:colla_chat/provider/linkman_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/common/data_listview.dart';

final Map<String, List<TileData>> mockTileData = {
  '未知': [
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
    var linkmen = Provider.of<LinkmenDataProvider>(context).linkmen;
    List<TileData> tileData = [];
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        var tile = TileData(
            avatar: linkman.avatar,
            title: linkman.name,
            subtitle: linkman.givenName,
            routeName: '/chat/setting');
        tileData.add(tile);
      }
    }
    Map<String, List<TileData>> linkmanTileData = {'linkmen': tileData};
    var body = DataListView(tileData: linkmanTileData);
    return Scaffold(
      //列表
      body: body,
    );
  }
}
