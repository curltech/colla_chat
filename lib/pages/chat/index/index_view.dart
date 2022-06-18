import 'package:colla_chat/pages/chat/index/end_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization.dart';
import '../../../provider/app_data.dart';
import '../../../provider/index_views.dart';
import '../channel/channel_widget.dart';
import '../chat/chat_target.dart';
import '../linkman/linkman_view.dart';
import '../me/me_widget.dart';

final List<String> widgetPosition = ['chat', 'linkman', 'channel', 'me'];

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
  var endDrawer = const EndDrawer();
  late Map<String, String> _widgetLabels;

  @override
  void initState() {
    super.initState();
    PageController pageController = PageController();
    var indexViewProvider = IndexViewProvider.instance;
    indexViewProvider.pageController = pageController;
    indexViewProvider.define(ChatTarget());
    indexViewProvider.define(LinkmanView());
    indexViewProvider.define(ChannelWidget());
    indexViewProvider.define(MeWidget());
  }

  _push(IndexViewProvider indexViewProvider, int currentIndex) {
    setState(() {
      _currentIndex = currentIndex;
    });
    String name = widgetPosition[currentIndex];
    indexViewProvider.push(name);
  }

  Widget _createLeftBar(BuildContext context) {
    return Consumer<IndexViewProvider>(
        builder: (context, indexViewProvider, child) {
      return SizedBox(
        width: 90.0,
        child: ListView(
          children: <Widget>[
            ListTile(
                iconColor: _getIconColor(0),
                title: Icon(Icons.chat),
                subtitle: Text(
                  _getLabel(0),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _getIconColor(0)),
                ),
                onTap: () {
                  _push(indexViewProvider, 0);
                }),
            ListTile(
                iconColor: _getIconColor(1),
                title: Icon(Icons.contacts),
                subtitle: Text(
                  _getLabel(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _getIconColor(1)),
                ),
                onTap: () {
                  _push(indexViewProvider, 1);
                }),
            ListTile(
                iconColor: _getIconColor(2),
                title: Icon(Icons.wifi_channel),
                subtitle: Text(
                  _getLabel(2),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _getIconColor(2)),
                ),
                onTap: () {
                  _push(indexViewProvider, 2);
                }),
            ListTile(
                iconColor: _getIconColor(3),
                title: Icon(Icons.person),
                subtitle: Text(
                  _getLabel(3),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _getIconColor(3)),
                ),
                onTap: () {
                  _push(indexViewProvider, 3);
                }),
          ],
        ),
      );
    });
  }

  Color? _getIconColor(int index) {
    if (index == _currentIndex) {
      return appDataProvider.themeData?.colorScheme.primary;
    } else {
      return Colors.grey;
    }
  }

  String _getLabel(int index) {
    String name = widgetPosition[index];
    String? label = _widgetLabels[name];
    label = label ?? '';

    return label;
  }

  Widget _createBottomBar(BuildContext context) {
    Widget bottomNavigationBar = Consumer<IndexViewProvider>(
        builder: (context, indexViewProvider, child) {
      return BottomNavigationBar(
        //底部按钮，移动版才有
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat), label: _getLabel(0)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.contacts), label: _getLabel(1)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.wifi_channel), label: _getLabel(2)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person), label: _getLabel(3)),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Provider.of<AppDataProvider>(context)
            .themeData
            ?.colorScheme
            .primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 14.0,
        unselectedFontSize: 14.0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (int index) {
          _push(indexViewProvider, index);
        },
      );
    });
    return bottomNavigationBar;
  }

  Widget _createPageView(BuildContext context) {
    var pageView = Consumer<IndexViewProvider>(
        builder: (context, indexViewProvider, child) {
      return PageView(
        controller: indexViewProvider.pageController,
        children: indexViewProvider.views,
        onPageChanged: (int index) {
          indexViewProvider.currentIndex = index;
        },
      );
    });

    return pageView;
  }

  Widget _createScaffold(BuildContext context) {
    var pageView = _createPageView(context);
    //左边栏，和底部按钮功能一样，在桌面版才有
    var leftToolBar = _createLeftBar(context);
    var bottomNavigationBar = _createBottomBar(context);
    Scaffold scaffold;
    //移动手机不需要左边栏，需要底部栏
    if (appDataProvider.mobile) {
      scaffold = Scaffold(
          body: Center(child: pageView),
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
              Expanded(child: pageView),
            ],
          )),
          endDrawer: endDrawer);
    }

    return scaffold;
  }

  @override
  Widget build(BuildContext context) {
    _widgetLabels = {
      'chat': AppLocalizations.instance.text('Chat'),
      'linkman': AppLocalizations.instance.text('Linkman'),
      'channel': AppLocalizations.instance.text('Channel'),
      'me': AppLocalizations.instance.text('Me'),
    };
    appDataProvider.changeSize(context);
    var scaffold = ChangeNotifierProvider.value(
        value: IndexViewProvider.instance,
        builder: (BuildContext context, Widget? child) {
          var scaffold = _createScaffold(context);
          return scaffold;
        });
    return scaffold;
  }

  @override
  void dispose() {
    // 释放资源
    super.dispose();
    var indexViewProvider = Provider.of<IndexViewProvider>(context);
    indexViewProvider.dispose();
  }
}
