import 'package:colla_chat/pages/chat/index/end_drawer.dart';
import 'package:colla_chat/platform.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization.dart';
import '../../../provider/app_data.dart';
import '../../../widgets/richtext/pages/home_page.dart';
import '../chat/chat_target.dart';
import '../linkman/linkman_page.dart';
import '../me/me.dart';

class Index extends StatefulWidget {
  final String title;

  const Index({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _IndexState();
  }
}

class _IndexState extends State<Index> {
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
  List<Widget> children = <Widget>[
    ChatTarget(),
    LinkmanPage(),
    HomePage(),
    Me()
  ];

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
                setState(() {
                  _currentIndex = 0;
                });
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
                setState(() {
                  _currentIndex = 1;
                });
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
                setState(() {
                  _currentIndex = 2;
                });
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
                setState(() {
                  _currentIndex = 3;
                });
              }),
        ],
      ),
    );
  }

  Color? _getIconColor(int index) {
    if (index == _currentIndex) {
      return Provider.of<AppDataProvider>(context)
          .themeData
          ?.colorScheme
          .primary;
    } else {
      return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    appDataProvider.changeSize(context);
    //左边栏，和底部按钮功能一样，在桌面版才有
    leftToolBar = _createLeftBar();
    bottomNavigationBar = _createBottomBar(context);
    Scaffold scaffold;
    var platformParams = PlatformParams.instance;
    //移动手机不需要左边栏，需要底部栏
    if (appDataProvider.mobile) {
      scaffold = Scaffold(
          body: Center(
              child: IndexedStack(
                  index: 0, children: <Widget>[children[_currentIndex]])),
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
              Expanded(
                  child: IndexedStack(
                      index: 0, children: <Widget>[children[_currentIndex]])),
            ],
          )),
          endDrawer: endDrawer);
    }
    return scaffold;
  }

  BottomNavigationBar _createBottomBar(BuildContext context) {
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
    setState(() {
      _currentIndex = index;
    });
  }
}
