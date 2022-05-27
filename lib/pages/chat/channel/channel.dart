import 'package:flutter/material.dart';

import '../../../widgets/data_listview.dart';

final Map<String, List<TileData>> mockTileData = {
  '未知': [
    TileData(
        icon: const Icon(Icons.collections),
        title: '李志群',
        routeName: '/chat/collection'),
    TileData(
        icon: const Icon(Icons.settings),
        title: '胡百水',
        routeName: '/chat/setting'),
  ]
};

//频道的页面
class Channel extends StatelessWidget {
  late final Map<String, List<TileData>> channelTileData = mockTileData;

  Channel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var body = DataListView(tileData: channelTileData);
    return Scaffold(
      //列表
      body: body,
    );
  }
}
