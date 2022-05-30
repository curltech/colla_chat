import 'package:colla_chat/pages/chat/channel/channel.dart';
import 'package:colla_chat/provider/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final _widgetLabels = ['聊天', '联系人', '频道', '我'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bottomNavigationBar = BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: const Icon(Icons.chat), label: '聊天'),
        BottomNavigationBarItem(icon: const Icon(Icons.contacts), label: '联系人'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.wifi_channel), label: '频道'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person), label: _widgetLabels.elementAt(3)),
      ],
      currentIndex: _currentIndex,
      selectedItemColor:
          Provider.of<ThemeDataProvider>(context).themeData?.primaryColorDark,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 14.0,
      unselectedFontSize: 14.0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: _onItemTapped,
    );
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
                  title: Text('聊天'),
                  onTap: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  }),
              ListTile(
                  leading: Icon(Icons.contacts),
                  title: Text('联系人'),
                  onTap: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  }),
              ListTile(
                  leading: Icon(Icons.wifi_channel),
                  title: Text('频道'),
                  onTap: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  }),
              ListTile(
                  leading: Icon(Icons.person),
                  title: Text('我'),
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
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Flutter Index',
          ),
          actions: [],
        ),
        body: Center(
            child: IndexedStack(
                index: 0, children: <Widget>[children[_currentIndex]])),
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar);
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
