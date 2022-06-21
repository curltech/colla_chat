import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/common/app_bar_view.dart';
import '../../../../../widgets/common/widget_mixin.dart';
import 'auto_discover_widget.dart';
import 'manual_add_widget.dart';

/// 地址增加页面
class AddressAddWidget extends StatefulWidget
    with BackButtonMixin, RouteNameMixin {
  const AddressAddWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddressAddWidgetState();

  @override
  String get routeName => 'mail_address';

  @override
  bool get withBack => true;
}

class _AddressAddWidgetState extends State<AddressAddWidget>
    with SingleTickerProviderStateMixin {
  late List<Widget> _children;
  late TabController _tabController;

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
  }

  @override
  Widget build(BuildContext context) {
    var tabBarView = Center(
        child: SizedBox(
            width: 350,
            height: 480,
            child: TabBarView(
              //physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: _children,
            )));
    List<Widget> rightWidgets = [
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
    ];
    var appBarView = AppBarView(
        title: 'Mail address add',
        rightActions: [
          AppLocalizations.t('Auto'),
          AppLocalizations.t('Manual')
        ],
        //rightWidgets: rightWidgets,
        rightCallBack: (int index) {
          _tabController.index = index;
        },
        child: tabBarView);
    return appBarView;
  }
}
