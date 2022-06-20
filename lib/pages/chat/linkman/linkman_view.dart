import 'package:colla_chat/pages/chat/linkman/linkman_add.dart';
import 'package:colla_chat/provider/linkman_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization.dart';
import '../../../provider/app_data_provider.dart';
import '../../../widgets/common/keep_alive_wrapper.dart';
import '../../../widgets/common/widget_mixin.dart';
import 'linkman_widget.dart';

//好友页面
class LinkmanView extends StatefulWidget with BackButtonMixin, RouteNameMixin {
  LinkmanView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanViewState();

  @override
  String get routeName => 'linkman';

  @override
  bool get withBack => false;
}

class _LinkmanViewState extends State<LinkmanView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  String _key = '';
  late List<Widget> _children;
  LinkmanProvider _linkmenDataProvider = LinkmanProvider();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 初始化子项集合
    var linkmanWidget =
        const KeepAliveWrapper(keepAlive: true, child: LinkmanWidget());
    var linkmanAddWidget =
        const KeepAliveWrapper(keepAlive: true, child: LinkmanAddWidget());
    _children = [
      linkmanWidget,
      linkmanAddWidget,
    ];
  }

  PopupMenuButton _popupMenuButton() {
    return PopupMenuButton<int>(
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            child: Text("Linkman"),
            value: 0,
          ),
          PopupMenuItem(
            child: Text("LinkmanAdd"),
            value: 1,
          ),
        ];
      },
      icon: Icon(
        Icons.add,
        color: Provider.of<AppDataProvider>(context)
            .themeData
            ?.colorScheme
            .primary,
      ),
      onSelected: (dynamic item) {
        setState(() {
          _tabController.index = item;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var tabBarView = TabBarView(
      controller: _tabController,
      children: _children,
    );
    var toolBar = ListTile(
      title: Text(AppLocalizations.t('Linkman'),
          style: TextStyle(
              color: Provider.of<AppDataProvider>(context)
                  .themeData
                  ?.colorScheme
                  .primary)),
      trailing: _popupMenuButton(),
    );
    var searchBar = Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.0),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: AppLocalizations.t('search'),
            suffixIcon: Icon(Icons.search),
          ),
          initialValue: _key,
          onChanged: (String val) {
            setState(() {
              _key = val;
            });
          },
          onTap: () {
            logger.i('search $_key');
          },
        ));
    var tabBar = RotatedBox(
        quarterTurns: 0,
        child: TabBar(
          controller: _tabController,
          indicatorColor: Provider.of<AppDataProvider>(context)
              .themeData
              ?.colorScheme
              .primary,
          labelColor: Provider.of<AppDataProvider>(context)
              .themeData
              ?.colorScheme
              .primary,
          tabs: const [Tab(text: 'Linkman'), Tab(text: 'LinkmanAdd')],
        ));
    return ChangeNotifierProvider.value(
      value: _linkmenDataProvider,
      child: Column(
        children: [toolBar, searchBar, tabBar, Expanded(child: tabBarView)],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
