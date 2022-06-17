import 'package:flutter/material.dart';

import '../../../../provider/app_data.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/data_listview.dart';

final Map<String, List<TileData>> settingTileData = {
  'Setting': [
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
class SettingWidget extends StatelessWidget {
  final Function? backCallBack;

  const SettingWidget({Key? key, this.backCallBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mine = AppBarView(
        title: 'Setting',
        backCallBack: backCallBack,
        child: DataListView(tileData: settingTileData));
    return mine;
  }
}
