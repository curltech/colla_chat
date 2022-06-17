import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/provider/index_views.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/app_data.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/data_listview.dart';
import 'collection/collection_widget.dart';
import 'mine_head_widget.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatelessWidget {
  final Function? backCallBack;
  final Function(dynamic target)? routerCallback;
  CollectionWidget collectionWidget = const CollectionWidget();
  SettingWidget settingWidget = const SettingWidget();

  MeWidget({Key? key, this.backCallBack, this.routerCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var indexViewProvider = Provider.of<IndexViewProvider>(context);
    indexViewProvider.define('collection', collectionWidget);
    indexViewProvider.define('setting', settingWidget);
    final Map<String, List<TileData>> mineTileData = {
      'Mine': [
        TileData(
          icon: Icon(Icons.collections,
              color: appDataProvider.themeData?.colorScheme.primary),
          title: '收藏',
          routeName: 'collection',
          // routerCallback: () {
          //   var routerCallback = this.routerCallback;
          //   if (routerCallback != null) {
          //     routerCallback(1);
          //   }
          // }
        ),
        TileData(
          icon: Icon(Icons.settings,
              color: appDataProvider.themeData?.colorScheme.primary),
          title: '设置',
          routeName: 'setting',
          // routerCallback: () {
          //   var routerCallback = this.routerCallback;
          //   if (routerCallback != null) {
          //     routerCallback(2);
          //   }
          // }
        ),
      ]
    };
    var me = AppBarView(
        title: 'Me',
        backCallBack: backCallBack,
        child: Column(children: <Widget>[
          MineHeadWidget(),
          DataListView(tileData: mineTileData)
        ]));
    return me;
  }
}
