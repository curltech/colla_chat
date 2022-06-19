import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/login/loading.dart';
import 'package:flutter/material.dart';

import 'auto_discover_widget.dart';
import 'manual_add_widget.dart';

/// 地址增加页面，一个Scaffold，IndexStack下的远程登录组件，注册组件和配置组件
class P2pLogin extends StatefulWidget {
  const P2pLogin({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pLoginState();
}

class _P2pLoginState extends State<P2pLogin>
    with SingleTickerProviderStateMixin {
  late List<Widget> _children;
  late TabController _tabController;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // 初始化子项集合
    var p2pLoginWidget = const AutoDiscoverWidget();
    var p2pRegisterWidget = const ManualAddWidget();
    _children = [
      p2pLoginWidget,
      p2pRegisterWidget,
    ];
    _tabController = TabController(length: _children.length, vsync: this);

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _visible = !_visible;
      });
    });
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
    var workspace = AnimatedOpacity(
        opacity: _visible ? 0.7 : 0.0,
        duration: Duration(seconds: 2),
        child: Center(
            child: SizedBox(
          width: 380,
          height: 500,
          child: tabBarView,
        )));
    return Scaffold(
        appBar: appBar,
        body: Stack(children: <Widget>[Loading(title: ''), workspace]));
  }
}
