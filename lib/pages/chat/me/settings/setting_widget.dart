import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/login/p2p_login_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/local_auth.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

final List<TileData> settingTileData = [
  TileData(
      prefix: Icon(Icons.generating_tokens,
          color: appDataProvider.themeData.colorScheme.primary),
      title: AppLocalizations.t('General')),
  TileData(
      prefix: Icon(Icons.high_quality,
          color: appDataProvider.themeData.colorScheme.primary),
      title: AppLocalizations.t('Advanced')),
  TileData(
      prefix: Icon(Icons.security,
          color: appDataProvider.themeData.colorScheme.primary),
      title: AppLocalizations.t('Security')),
  TileData(
      prefix: Icon(Icons.privacy_tip,
          color: appDataProvider.themeData.colorScheme.primary),
      title: AppLocalizations.t('Privacy')),
  TileData(
      prefix:
          Icon(Icons.usb, color: appDataProvider.themeData.colorScheme.primary),
      title: AppLocalizations.t('About')),
];

//设置页面，带有回退回调函数
class SettingWidget extends StatefulWidget with TileDataMixin {
  ///类变量，不用每次重建
  final DataListView dataListView = DataListView(tileData: settingTileData);
  final AuthMethod authMethod = AuthMethod.app;

  SettingWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingWidgetState();
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

class _SettingWidgetState extends State<SettingWidget> {
  bool? loginStatus;

  @override
  void initState() {
    super.initState();
    _buildLocalAuthenticate();
  }

  void _buildLocalAuthenticate() async {
    if (widget.authMethod == AuthMethod.local) {
      loginStatus =
          await LocalAuthUtil.authenticate(localizedReason: 'Authenticate');
      setState(() {});
    }
  }

  Widget _buildAppAuthenticate() {
    if (widget.authMethod == AuthMethod.app) {
      P2pLoginWidget p2pLoginWidget =
          P2pLoginWidget(onAuthenticate: (bool data) {
        loginStatus = data;
        setState(() {});
      });
      return p2pLoginWidget;
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    var setting = KeepAliveWrapper(
        child: AppBarView(
            title: Text(AppLocalizations.t(widget.title)),
            withLeading: widget.withLeading,
            child: IndexedStack(
              index: (loginStatus == null) ? 0 : 1,
              children: [
                _buildAppAuthenticate(),
                (loginStatus != null && loginStatus!)
                    ? widget.dataListView
                    : Center(
                        child:
                            Text(AppLocalizations.t('Authenticate failure'))),
              ],
            )));
    return setting;
  }
}
