import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/login/loading.dart';
import 'package:flutter/material.dart';

import '../../../widgets/common/keep_alive_wrapper.dart';
import 'p2p_login_widget.dart';
import 'p2p_register_widget.dart';
import 'p2p_setting_widget.dart';

/// 远程登录页面，一个Scaffold，IndexStack下的远程登录组件，注册组件和配置组件
class P2pLogin extends StatefulWidget {
  const P2pLogin({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pLoginState();
}

class _P2pLoginState extends State<P2pLogin>
    with SingleTickerProviderStateMixin {
  late List<Widget> _children;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 初始化子项集合
    var p2pLoginWidget = const KeepAliveWrapper(child: P2pLoginWidget());
    var p2pRegisterWidget = const KeepAliveWrapper(child: P2pRegisterWidget());
    var p2pSettingWidget = const KeepAliveWrapper(child: P2pSettingWidget());
    _children = [
      p2pLoginWidget,
      p2pRegisterWidget,
      p2pSettingWidget,
    ];
    _tabController = TabController(length: _children.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    var tabBarView = TabBarView(
      controller: _tabController,
      children: _children,
    );
    var appBar = AppBar(
      title: Text(AppLocalizations.t('Login')),
      actions: [
        IconButton(
            onPressed: () async {
              _tabController.index = 0;
            },
            icon: const Icon(Icons.login),
            tooltip: AppLocalizations.t('Login')),
        IconButton(
          onPressed: () async {
            _tabController.index = 1;
          },
          icon: const Icon(Icons.app_registration),
          tooltip: AppLocalizations.t('Register'),
        ),
        IconButton(
          onPressed: () async {
            _tabController.index = 2;
          },
          icon: const Icon(Icons.settings),
          tooltip: AppLocalizations.t('Setting'),
        ),
      ],
    );
    return Scaffold(
        appBar: appBar,
        body: Stack(children: <Widget>[
          Loading(title: ''),
          Opacity(
              opacity: 0.7,
              child: Center(
                  child: SizedBox(
                width: 380,
                height: 500,
                child: tabBarView,
              )))
        ]));
  }
}
