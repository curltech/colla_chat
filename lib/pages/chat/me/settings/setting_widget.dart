import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/localization.dart';
import '../../../../provider/app_data_provider.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/data_listtile.dart';
import '../../../../widgets/data_bind/data_listview.dart';

final List<TileData> settingTileData = [
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
];

//设置页面，带有回退回调函数
class SettingWidget extends StatelessWidget with TileDataMixin {
  ///类变量，不用每次重建
  final DataListView dataListView = DataListView(tileData: settingTileData);

  SettingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var setting = KeepAliveWrapper(
        child: AppBarView(
            title: Text(AppLocalizations.t('Setting')),
            withLeading: withLeading,
            child: dataListView));
    return setting;
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'setting';

  @override
  Icon get icon => const Icon(Icons.settings);

  @override
  String get title => 'Setting';
}
