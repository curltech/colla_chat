import 'package:flutter/material.dart';

import '../../../widgets/data_tile.dart';

final List<List<TileData>> meTileData = [
  [
    TileData(
        icon: const Icon(Icons.collections),
        title: '收藏',
        routeName: '/chat/collection'),
    TileData(
        icon: const Icon(Icons.settings),
        title: '设置',
        routeName: '/chat/setting'),
  ],
];

//我的页面
class Me extends StatelessWidget {
  final List<List<TileData>> tileData = meTileData;

  Me({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    for (var groupTile in tileData) {
      for (var tile in groupTile) {
        var widget = Container(
            margin: const EdgeInsets.only(top: 20.0),
            color: Colors.white,
            child: Column(children: <Widget>[
              DataTile(tileData: tile),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: Divider(
                  height: 0.5,
                  color: Colors.grey,
                ),
              ),
            ]));
        children.add(widget);
      }
    }
    return Scaffold(
      //列表
      body: ListView(
        children: children,
      ),
    );
  }
}
