import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization.dart';
import '../../../provider/app_data.dart';
import '../../../widgets/richtext/pages/home_page.dart';
import '../chat/chat_target.dart';
import '../linkman/linkman.dart';
import '../me/me.dart';

class MobileIndex extends StatefulWidget {
  final String title;

  const MobileIndex({Key? key, required this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MobileIndexState();
  }
}

class _MobileIndexState extends State<MobileIndex> {
  int _currentIndex = 0;
  final _widgetLabels = [
    AppLocalizations.instance.text('Chat'),
    AppLocalizations.instance.text('Linkman'),
    AppLocalizations.instance.text('Channel'),
    AppLocalizations.instance.text('Me')
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      elevation: 0,
      centerTitle: false,
      title: Text(
        AppLocalizations.instance.text('CollaChat'),
      ),
      actions: [],
    );
    var bottomNavigationBar = BottomNavigationBar(
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
          Provider.of<AppDataProvider>(context).themeData?.primaryColorDark,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 14.0,
      unselectedFontSize: 14.0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: _onItemTapped,
    );
    //左边栏，和底部按钮功能一样，在桌面版才有
    var drawer = Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        color: Colors.grey.shade800,
        child: Drawer(
          child: ListView(
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountEmail: Text('hujs@colla.cc'),
                accountName: Text('胡劲松'),
              ),
              ListTile(
                  leading: Icon(Icons.chat),
                  title: Text(_widgetLabels.elementAt(0)),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentIndex = 0;
                    });
                  }),
              ListTile(
                  leading: Icon(Icons.contacts),
                  title: Text(_widgetLabels.elementAt(1)),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentIndex = 1;
                    });
                  }),
              ListTile(
                  leading: Icon(Icons.wifi_channel),
                  title: Text(_widgetLabels.elementAt(2)),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentIndex = 2;
                    });
                  }),
              ListTile(
                  leading: Icon(Icons.person),
                  title: Text(_widgetLabels.elementAt(3)),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentIndex = 3;
                    });
                  }),
            ],
          ),
        ));
    //右边栏，用于展示当前用户信息，当前用户的配置信息
    var endDrawer = Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        color: Colors.grey.shade800,
        child: Drawer(
          child: ListView(
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountEmail: Text('hujs@colla.cc'),
                accountName: Text('胡劲松'),
              ),
              ListTile(
                  leading: Icon(Icons.chat),
                  title: Text(_widgetLabels.elementAt(0)),
                  onTap: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  }),
              ListTile(
                  leading: Icon(Icons.contacts),
                  title: Text(_widgetLabels.elementAt(1)),
                  onTap: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  }),
              ListTile(
                  leading: Icon(Icons.wifi_channel),
                  title: Text(_widgetLabels.elementAt(2)),
                  onTap: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  }),
              ListTile(
                  leading: Icon(Icons.person),
                  title: Text(_widgetLabels.elementAt(3)),
                  onTap: () {
                    setState(() {
                      _currentIndex = 3;
                    });
                  }),
            ],
          ),
        ));
    List<Widget> children = <Widget>[ChatTarget(), Linkman(), HomePage(), Me()];
    return Scaffold(
        appBar: appBar,
        body: Center(
            child: IndexedStack(
                index: 0, children: <Widget>[children[_currentIndex]])),
        drawer: drawer,
        endDrawer: endDrawer,
        bottomNavigationBar: bottomNavigationBar);
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
