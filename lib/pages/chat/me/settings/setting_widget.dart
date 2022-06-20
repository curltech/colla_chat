import 'package:flutter/material.dart';

import '../../../../provider/app_data_provider.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/data_group_listview.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/widget_mixin.dart';

final Map<TileData, List<TileData>> settingTileData = {
  TileData(title: 'Setting'): [
    TileData(
        icon: Icon(Icons.security,
            color: appDataProvider.themeData?.colorScheme.primary),
        title: 'Security'),
    TileData(
        icon: Icon(Icons.privacy_tip,
            color: appDataProvider.themeData?.colorScheme.primary),
        title: 'Privacy'),
    TileData(
        icon: Icon(Icons.generating_tokens,
            color: appDataProvider.themeData?.colorScheme.primary),
        title: 'General'),
    TileData(
        icon: Icon(Icons.high_quality,
            color: appDataProvider.themeData?.colorScheme.primary),
        title: 'Advanced'),
    TileData(
        icon: Icon(Icons.usb,
            color: appDataProvider.themeData?.colorScheme.primary),
        title: 'About'),
  ]
};

//设置页面，带有回退回调函数
class SettingWidget extends StatelessWidget
    with BackButtonMixin, RouteNameMixin {
  final Function? backCallBack;

  SettingWidget({Key? key, this.backCallBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var setting = AppBarView(
        title: 'Setting',
        withBack: withBack,
        backCallBack: backCallBack,
        child: GroupDataListView(tileData: settingTileData));
    return setting;
  }

  @override
  bool get withBack => true;

  @override
  String get routeName => 'setting';
}
