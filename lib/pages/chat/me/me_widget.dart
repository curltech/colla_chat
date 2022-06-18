import 'package:colla_chat/pages/chat/me/settings/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/provider/index_views.dart';
import 'package:flutter/material.dart';

import '../../../provider/app_data.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/data_listview.dart';
import '../../../widgets/common/widget_mixin.dart';
import 'collection/collection_widget.dart';
import 'me_head_widget.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatelessWidget with BackButtonMixin, RouteNameMixin {
  CollectionWidget collectionWidget = CollectionWidget();
  SettingWidget settingWidget = SettingWidget();
  PersonalInfoWidget personalInfoWidget = PersonalInfoWidget();

  MeWidget({Key? key}) : super(key: key) {
    var indexViewProvider = IndexViewProvider.instance;
    indexViewProvider.define(collectionWidget);
    indexViewProvider.define(settingWidget);
    indexViewProvider.define(personalInfoWidget);
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
          const MeHeadWidget(),
          DataListView(tileData: mineTileData)
        ]));
    return me;
  }

  @override
  bool get withBack => true;

  @override
  String get routeName => 'me';
}
