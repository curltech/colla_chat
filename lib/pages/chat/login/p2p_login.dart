import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

import '../../../widgets/style/platform_widget_factory.dart';
import 'loading.dart';
import 'p2p_login_widget.dart';
import 'p2p_register_widget.dart';
import 'p2p_setting_widget.dart';

/// 远程登录页面，一个Scaffold，IndexStack下的远程登录组件，注册组件和配置组件
class P2pLogin extends StatefulWidget {
  final P2pLoginWidget p2pLoginWidget = const P2pLoginWidget();
  final P2pRegisterWidget p2pRegisterWidget = const P2pRegisterWidget();
  final P2pSettingWidget p2pSettingWidget = const P2pSettingWidget();
  late final List<Widget> _children;
  late final PageController controller = PageController();

  P2pLogin({Key? key}) : super(key: key) {
    // 初始化子项集合
    _children = [
      p2pLoginWidget,
      p2pRegisterWidget,
      p2pSettingWidget,
    ];
  }

  @override
  State<StatefulWidget> createState() => _P2pLoginState();
}

class _P2pLoginState extends State<P2pLogin> {
  @override
  void initState() {
    super.initState();
  }

  _animateToPage(int index) {
    widget.controller.animateToPage(index,
        duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    appDataProvider.changeSize(context);
    var pageView = PageView(
      //physics: const NeverScrollableScrollPhysics(),
      controller: widget.controller,
      children: widget._children,
    );
    var appBar = AppBar(
      automaticallyImplyLeading: false,
      title: Text(AppLocalizations.t('Login')),
      actions: [
        IconButton(
            onPressed: () {
              _animateToPage(0);
            },
            icon: const Icon(Icons.login),
            tooltip: AppLocalizations.t('Login')),
        IconButton(
          onPressed: () {
            _animateToPage(1);
          },
          icon: const Icon(Icons.app_registration),
          tooltip: AppLocalizations.t('Register'),
        ),
        IconButton(
          onPressed: () {
            _animateToPage(2);
          },
          icon: const Icon(Icons.settings),
          tooltip: AppLocalizations.t('Setting'),
        ),
      ],
    );
    var workspace = Center(
        child: platformWidgetFactory.buildSizedBox(
      height: appDataProvider.mobileSize.height,
      width: appDataProvider.mobileSize.width,
      child: pageView,
    ));
    return Scaffold(
        appBar: appBar,
        body: Stack(children: <Widget>[
          Opacity(
            opacity: 1,
            child: loadingWidget,
          ),
          workspace
        ]));
  }
}
