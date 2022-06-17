import 'package:flutter/material.dart';

import '../../../provider/app_data.dart';
import '../../../widgets/common/data_listview.dart';
import 'mine_head_widget.dart';

//我的页面，带有路由回调函数
class MineWidget extends StatelessWidget {
  final Function(dynamic target)? routerCallback;

  MineWidget({Key? key, this.routerCallback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, List<TileData>> mineTileData = {
      'Mine': [
        TileData(
            icon: Icon(Icons.collections,
                color: appDataProvider.themeData?.colorScheme.primary),
            title: '收藏',
            routerCallback: () {
              var routerCallback = this.routerCallback;
              if (routerCallback != null) {
                routerCallback(1);
              }
            }),
        TileData(
            icon: Icon(Icons.settings,
                color: appDataProvider.themeData?.colorScheme.primary),
            title: '设置',
            routerCallback: () {
              var routerCallback = this.routerCallback;
              if (routerCallback != null) {
                routerCallback(2);
              }
            }),
      ]
    };
    var mine = Column(children: <Widget>[
      MineHeadWidget(),
      Expanded(child: DataListView(tileData: mineTileData))
    ]);
    return mine;
  }
}
