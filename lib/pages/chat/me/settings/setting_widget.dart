import 'package:colla_chat/pages/login/p2p_login_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/advanced_setting_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/general/general_setting_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/privacy/peer_profile_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/security/security_setting_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
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
  final AdvancedSettingWidget advancedSettingWidget = AdvancedSettingWidget();
  final PeerProfileEditWidget peerProfileEditWidget =
      const PeerProfileEditWidget();
  final SecuritySettingWidget securitySettingWidget = SecuritySettingWidget();
  final AuthMethod authMethod = AuthMethod.app;
  late final List<TileData> settingTileData;

  SettingWidget({super.key}) {
    indexWidgetProvider.define(generalSettingWidget);
    indexWidgetProvider.define(advancedSettingWidget);
    indexWidgetProvider.define(peerProfileEditWidget);
    indexWidgetProvider.define(securitySettingWidget);
    List<TileDataMixin> mixins = [
      generalSettingWidget,
      advancedSettingWidget,
      peerProfileEditWidget,
      securitySettingWidget
    ];
    settingTileData = TileData.from(mixins);
    for (var tile in settingTileData) {
      tile.dense = true;
    }
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
  IconData get iconData => Icons.settings;

  @override
  String get title => 'Setting';
}

class _SettingWidgetState extends State<SettingWidget> {
  //登录状态，null表示登录成功，否则表示登录失败原因，初始化的为init表示未开始登录
  String? loginStatus = 'init';

  @override
  void initState() {
    super.initState();
    _buildLocalAuthenticate();
  }

  void _buildLocalAuthenticate() async {
    if (widget.authMethod == AuthMethod.local) {
      setState(() async {
        loginStatus =
            await LocalAuthUtil.authenticate(localizedReason: 'Authenticate');
      });
    }
  }

  Widget _buildAppAuthenticate() {
    if (widget.authMethod == AuthMethod.app) {
      P2pLoginWidget p2pLoginWidget = P2pLoginWidget(
          credential: myself.myselfPeer.loginName,
          onAuthenticate: (String? data) {
            setState(() {
              loginStatus = data;
            });
          });
      return p2pLoginWidget;
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = DataListView(tileData: widget.settingTileData);
    var setting = KeepAliveWrapper(
        child: AppBarView(
            title: widget.title,
            withLeading: widget.withLeading,
            child: (loginStatus != null) ? _buildAppAuthenticate() : child));
    return setting;
  }
}
