import 'package:flutter/material.dart';

import '../../../provider/app_data.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/data_listview.dart';

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
            callback: () {
              var routerCallback = this.routerCallback;
              if (routerCallback != null) {
                routerCallback(1);
              }
            }),
        TileData(
            icon: Icon(Icons.settings,
                color: appDataProvider.themeData?.colorScheme.primary),
            title: '设置',
            callback: () {
              var routerCallback = this.routerCallback;
              if (routerCallback != null) {
                routerCallback(2);
              }
            }),
      ]
    };
    var mine =
        AppBarView(title: 'Mine', child: DataListView(tileData: mineTileData));
    return mine;
  }
}
