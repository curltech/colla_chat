import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/login/p2p_login_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/advanced_setting_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/general/general_setting_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/privacy/privacy_setting_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/security/security_setting_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/local_auth.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//设置页面，带有回退回调函数
class SettingWidget extends StatefulWidget with TileDataMixin {
  final GeneralSettingWidget generalSettingWidget =
      const GeneralSettingWidget();
  final AdvancedSettingWidget advancedSettingWidget =
      const AdvancedSettingWidget();
  final PrivacySettingWidget privacySettingWidget =
      const PrivacySettingWidget();
  final SecuritySettingWidget securitySettingWidget =
      const SecuritySettingWidget();
  final AuthMethod authMethod = AuthMethod.app;
  late final Widget child;

  SettingWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(generalSettingWidget);
    indexWidgetProvider.define(advancedSettingWidget);
    indexWidgetProvider.define(privacySettingWidget);
    indexWidgetProvider.define(securitySettingWidget);
    List<TileDataMixin> mixins = [
      generalSettingWidget,
      advancedSettingWidget,
      privacySettingWidget,
      securitySettingWidget
    ];
    final List<TileData> meTileData = TileData.from(mixins);
    for (var tile in meTileData) {
      tile.dense = true;
    }
    child = Expanded(child: DataListView(tileData: meTileData));
  }

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
                    ? widget.child
                    : Center(
                        child:
                            Text(AppLocalizations.t('Authenticate failure'))),
              ],
            )));
    return setting;
  }
}
