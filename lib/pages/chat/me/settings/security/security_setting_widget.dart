import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/security/password_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 安全设置组件，包括修改密码，登录选项（免登录设置），加密选项（加密算法，signal）
class SecuritySettingWidget extends StatefulWidget with TileDataMixin {
  final PasswordWidget passwordWidget = const PasswordWidget();
  late final List<TileData> securitySettingTileData;

  SecuritySettingWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(passwordWidget);
    List<TileDataMixin> mixins = [
      passwordWidget,
    ];
    securitySettingTileData = TileData.from(mixins);
    for (var tile in securitySettingTileData) {
      tile.dense = true;
    }
  }

  @override
  State<StatefulWidget> createState() => _SecuritySettingWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'security_setting';

  @override
  Icon get icon => const Icon(Icons.security);

  @override
  String get title => 'Security Setting';
}

class _SecuritySettingWidgetState extends State<SecuritySettingWidget> {
  @override
  void initState() {
    super.initState();
    appDataProvider.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildSettingWidget(BuildContext context) {
    Widget securitySettingTile =
        DataListView(tileData: widget.securitySettingTileData);
    var autoLoginTile = CheckboxListTile(
        title: Text(AppLocalizations.t('Auto Login')),
        dense: true,
        activeColor: myself.primary,
        value: appDataProvider.autoLogin,
        onChanged: (bool? autoLogin) async {
          autoLogin = autoLogin ?? false;
          if (myself.autoLogin == autoLogin) {
            return;
          }
          myself.autoLogin = autoLogin;
          if (autoLogin) {
            var loginName = myself.myselfPeer.loginName;
            var password = myself.password;
            await myselfPeerService.saveAutoCredential(loginName, password!);
            appDataProvider.autoLogin = true;
          } else {
            await myselfPeerService.removeAutoCredential();
            appDataProvider.autoLogin = false;
          }
        });
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[securitySettingTile, autoLoginTile],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: widget.title,
        child: _buildSettingWidget(context));
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
