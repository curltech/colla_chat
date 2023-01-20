import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/mail/address/auto_discover_widget.dart';
import 'package:colla_chat/pages/chat/me/mail/address/manual_add_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 地址增加页面
class AddressAddWidget extends StatefulWidget with TileDataMixin {
  const AddressAddWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddressAddWidgetState();

  @override
  String get routeName => 'mail_address_add';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.contact_mail);

  @override
  String get title => 'MailAddressAdd';
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
            height: 450,
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
        title: widget.title,
        withLeading: widget.withLeading,
        rightPopupMenus: [
          AppBarPopupMenu(title: AppLocalizations.t('Auto')),
          AppBarPopupMenu(title: AppLocalizations.t('Manual'))
        ],
        child: tabBarView);
    return appBarView;
  }
}
