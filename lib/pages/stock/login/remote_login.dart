import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/login/remote_login_widget.dart';
import 'package:colla_chat/pages/stock/login/remote_register_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// 远程登录页面，一个Scaffold，IndexStack下的远程登录组件，注册组件和配置组件
class RemoteLogin extends StatefulWidget {
  const RemoteLogin({super.key});

  @override
  State<StatefulWidget> createState() => _RemoteLoginState();
}

class _RemoteLoginState extends State<RemoteLogin> {
  int _currentIndex = 0;
  late List<Widget> _children;

  @override
  void initState() {
    super.initState();
    // 初始化子项集合
    var remoteLoginWidget = const RemoteLoginWidget();
    var remoteRegisterWidget = const RemoteRegisterWidget();
    _children = [
      remoteLoginWidget,
      remoteRegisterWidget,
    ];
  }

  @override
  Widget build(BuildContext context) {
    var stack = IndexedStack(
      index: _currentIndex,
      children: _children,
    );
    var appBar = AppBar(
      title: AutoSizeText(AppLocalizations.t('Login')),
      actions: [
        IconButton(
          onPressed: () async {
            setState(() {
              _currentIndex = 1;
            });
          },
          icon: const Icon(Icons.app_registration),
          tooltip: AppLocalizations.t('Register'),
        ),
        IconButton(
            onPressed: () async {
              setState(() {
                _currentIndex = 0;
              });
            },
            icon: const Icon(Icons.login),
            tooltip: AppLocalizations.t('Login')),
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
