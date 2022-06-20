import 'package:colla_chat/l10n/localization.dart';
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
    var autoDiscoverWidget = const AutoDiscoverWidget();
    var manualAddWidget = const ManualAddWidget();
    _children = [
      autoDiscoverWidget,
      manualAddWidget,
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
      automaticallyImplyLeading: false,
      title: Text(AppLocalizations.t('Add email address')),
      actions: [
        IconButton(
            onPressed: () async {
              _tabController.index = 0;
            },
            icon: const Icon(Icons.auto_awesome),
            tooltip: AppLocalizations.t('Auto')),
        IconButton(
          onPressed: () async {
            _tabController.index = 1;
          },
          icon: const Icon(Icons.fiber_manual_record),
          tooltip: AppLocalizations.t('Manual'),
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
    return Scaffold(appBar: appBar, body: Stack(children: <Widget>[workspace]));
  }
}
