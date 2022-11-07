import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

final List<TileData> settingTileData = [
  TileData(
      prefix: Icon(Icons.generating_tokens,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: AppLocalizations.t('General')),
  TileData(
      prefix: Icon(Icons.high_quality,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: AppLocalizations.t('Advanced')),
  TileData(
      prefix: Icon(Icons.security,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: AppLocalizations.t('Security')),
  TileData(
      prefix: Icon(Icons.privacy_tip,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: AppLocalizations.t('Privacy')),
  TileData(
      prefix: Icon(Icons.usb,
          color: appDataProvider.themeData?.colorScheme.primary),
      title: AppLocalizations.t('About')),
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
            title: Text(AppLocalizations.t(title)),
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
