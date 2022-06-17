import 'package:colla_chat/pages/chat/index/end_drawer.dart';
import 'package:colla_chat/platform.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization.dart';
import '../../../provider/app_data.dart';
import '../../../widgets/common/keep_alive_wrapper.dart';
import '../chat/chat_target.dart';
import '../linkman/linkman_page.dart';
import '../me/collection/collection_widget.dart';
import '../me/me_view.dart';

class IndexView extends StatefulWidget {
  final String title;

  const IndexView({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return IndexViewState();
  }
}

class IndexViewState extends State<IndexView>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final _widgetLabels = [
    AppLocalizations.instance.text('Chat'),
    AppLocalizations.instance.text('Linkman'),
    AppLocalizations.instance.text('Channel'),
    AppLocalizations.instance.text('Me')
  ];
  var endDrawer = const EndDrawer();
  late SizedBox leftToolBar;
  late BottomNavigationBar bottomNavigationBar;
  List<Widget> _children = <Widget>[];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _children = <Widget>[
      KeepAliveWrapper(child: ChatTarget()),
      const KeepAliveWrapper(child: LinkmanPage()),
      KeepAliveWrapper(child: CollectionWidget()),
      const KeepAliveWrapper(
          child: MeView(
        title: 'Me',
      ))
    ];
    _tabController = TabController(length: _children.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  SizedBox _createLeftBar() {
    return SizedBox(
      width: 90.0,
      child: ListView(
        children: <Widget>[
          ListTile(
              iconColor: _getIconColor(0),
              title: Icon(Icons.chat),
              subtitle: Text(
                _widgetLabels.elementAt(0),
                textAlign: TextAlign.center,
                style: TextStyle(color: _getIconColor(0)),
              ),
              onTap: () {
                _tabController.index = 0;
              }),
          ListTile(
              iconColor: _getIconColor(1),
              title: Icon(Icons.contacts),
              subtitle: Text(
                _widgetLabels.elementAt(1),
                textAlign: TextAlign.center,
                style: TextStyle(color: _getIconColor(1)),
              ),
              onTap: () {
                _tabController.index = 1;
              }),
          ListTile(
              iconColor: _getIconColor(2),
              title: Icon(Icons.wifi_channel),
              subtitle: Text(
                _widgetLabels.elementAt(2),
                textAlign: TextAlign.center,
                style: TextStyle(color: _getIconColor(2)),
              ),
              onTap: () {
                _tabController.index = 2;
              }),
          ListTile(
              iconColor: _getIconColor(3),
              title: Icon(Icons.person),
              subtitle: Text(
                _widgetLabels.elementAt(3),
                textAlign: TextAlign.center,
                style: TextStyle(color: _getIconColor(3)),
              ),
              onTap: () {
                _tabController.index = 3;
              }),
        ],
      ),
    );
  }

  Color? _getIconColor(int index) {
    if (index == _tabController.index) {
      return Provider.of<AppDataProvider>(context)
          .themeData
          ?.colorScheme
          .primary;
    } else {
      return Colors.grey;
    }
  }

  BottomNavigationBar _createBottomBar(BuildContext context) {
    var index = _tabController.index;
    BottomNavigationBar bottomNavigationBar = BottomNavigationBar(
      //底部按钮，移动版才有
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: const Icon(Icons.chat), label: _widgetLabels.elementAt(0)),
        BottomNavigationBarItem(
            icon: const Icon(Icons.contacts),
            label: _widgetLabels.elementAt(1)),
        BottomNavigationBarItem(
            icon: const Icon(Icons.wifi_channel),
            label: _widgetLabels.elementAt(2)),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person), label: _widgetLabels.elementAt(3)),
      ],
      currentIndex: _currentIndex,
      selectedItemColor:
          Provider.of<AppDataProvider>(context).themeData?.colorScheme.primary,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 14.0,
      unselectedFontSize: 14.0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: _onItemTapped,
    );
    return bottomNavigationBar;
  }

  void _onItemTapped(int index) {
    _tabController.index = index;
  }

  @override
  Widget build(BuildContext context) {
    appDataProvider.changeSize(context);
    //左边栏，和底部按钮功能一样，在桌面版才有
    leftToolBar = _createLeftBar();
    bottomNavigationBar = _createBottomBar(context);
    Scaffold scaffold;
    var platformParams = PlatformParams.instance;
    var tabBarView = TabBarView(
      controller: _tabController,
      children: _children,
    );
    //移动手机不需要左边栏，需要底部栏
    if (appDataProvider.mobile) {
      scaffold = Scaffold(
          body: Center(child: tabBarView),
          endDrawer: endDrawer,
          bottomNavigationBar: bottomNavigationBar);
    } else {
      //桌面版不需要底部栏，需要固定的左边栏
      scaffold = Scaffold(
          body: Center(
              child: Row(
            children: <Widget>[
              leftToolBar,
              const VerticalDivider(thickness: 0.5),
              Expanded(child: tabBarView),
            ],
          )),
          endDrawer: endDrawer);
    }
    return scaffold;
  }

  @override
  void dispose() {
    // 释放资源
    _tabController.dispose();
    super.dispose();
  }
}
