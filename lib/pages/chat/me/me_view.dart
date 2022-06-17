import 'package:colla_chat/pages/chat/me/mine_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';
import '../../../widgets/common/keep_alive_wrapper.dart';
import 'collection/collection_widget.dart';

///我的视图，里面包含主视图mine，收藏和设置视图共三个视图，本身是一个tabbarview
class MeView extends StatefulWidget {
  final String title;

  const MeView({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MeViewState();
  }
}

class MeViewState extends State<MeView> with SingleTickerProviderStateMixin {
  var _children = <Widget>[];
  final _subviewLabels = [
    AppLocalizations.instance.text('Mine'),
    AppLocalizations.instance.text('Collection'),
    AppLocalizations.instance.text('Setting'),
  ];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _children = <Widget>[
      KeepAliveWrapper(child: MineWidget(
        routerCallback: (dynamic target) {
          if (target != null) {
            int index = target as int;
            _tabController.index = index;
          }
        },
      )),
      KeepAliveWrapper(child: CollectionWidget()),
      KeepAliveWrapper(child: SettingWidget(
        backCallBack: () {
          _tabController.index = 0;
        },
      ))
    ];
    _tabController = TabController(length: _children.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var tabBarView =
        TabBarView(controller: _tabController, children: _children);
    return tabBarView;
  }

  @override
  void dispose() {
    // 释放资源
    _tabController.dispose();
    super.dispose();
  }
}
