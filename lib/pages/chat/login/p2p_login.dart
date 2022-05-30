import 'package:colla_chat/pages/stock/login/remote_login_widget.dart';
import 'package:colla_chat/pages/stock/login/remote_register_widget.dart';
import 'package:flutter/material.dart';

import 'p2p_login_widget.dart';
import 'p2p_register_widget.dart';
import 'p2p_setting_widget.dart';

/// 远程登录页面，一个Scaffold，IndexStack下的远程登录组件，注册组件和配置组件
class P2pLogin extends StatefulWidget {
  const P2pLogin({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _P2pLoginState();
}

class _P2pLoginState extends State<P2pLogin> {
  int _currentIndex = 0;
  late List<Widget> _children;

  @override
  void initState() {
    super.initState();
    // 初始化子项集合
    var p2pLoginWidget = const P2pLoginWidget();
    var p2pRegisterWidget = const P2pRegisterWidget();
    var p2pSettingWidget = const P2pSettingWidget();
    _children = [
      p2pLoginWidget,
      p2pRegisterWidget,
      p2pSettingWidget,
    ];
  }

  @override
  Widget build(BuildContext context) {
    var stack = IndexedStack(
      index: _currentIndex,
      children: _children,
    );
    var appBar = AppBar(
      title: Text('登录'),
      actions: [
        IconButton(
            onPressed: () async {
              setState(() {
                _currentIndex = 0;
              });
            },
            icon: const Icon(Icons.login),
            tooltip: '登录'),
        IconButton(
          onPressed: () async {
            setState(() {
              _currentIndex = 1;
            });
          },
          icon: const Icon(Icons.app_registration),
          tooltip: '注册',
        ),
        IconButton(
          onPressed: () async {
            setState(() {
              _currentIndex = 2;
            });
          },
          icon: const Icon(Icons.settings),
          tooltip: '设置',
        ),
      ],
    );
    return Scaffold(
        appBar: appBar,
        body: Center(
            child: SizedBox(
          width: 380,
          height: 500,
          child: stack,
        )));
  }
}
