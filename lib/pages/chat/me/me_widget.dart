import 'package:colla_chat/pages/chat/me/settings/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/provider/index_views.dart';
import 'package:flutter/material.dart';

import '../../../provider/app_data.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/data_listview.dart';
import 'collection/collection_widget.dart';
import 'mine_head_widget.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatelessWidget {
  CollectionWidget collectionWidget = const CollectionWidget();
  SettingWidget settingWidget = const SettingWidget(
    withBack: true,
  );
  PersonalInfoWidget personalInfoWidget = const PersonalInfoWidget(
    withBack: true,
  );

  MeWidget({Key? key}) : super(key: key) {
    var indexViewProvider = IndexViewProvider.instance;
    indexViewProvider.define('collection', collectionWidget);
    indexViewProvider.define('setting', settingWidget);
    indexViewProvider.define('personal_info', personalInfoWidget);
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(children: <Widget>[
          const MineHeadWidget(),
          DataListView(tileData: mineTileData)
        ]));
    return me;
  }
}
