import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/app_data_provider.dart';
import '../../../provider/index_widget_provider.dart';

///mobile底边栏，用于指示当前主页面
class BottomBar extends StatefulWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BottomBarState();
  }
}

class _BottomBarState extends State<BottomBar> {
  @override
  initState() {
    super.initState();
  }

  Widget _createBottomBar(BuildContext context) {
    Widget bottomNavigationBar = Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      return BottomNavigationBar(
        //底部按钮，移动版才有
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat),
              label: indexWidgetProvider.getLabel(0)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.contacts),
              label: indexWidgetProvider.getLabel(1)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.wifi_channel),
              label: indexWidgetProvider.getLabel(2)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: indexWidgetProvider.getLabel(3)),
        ],
        currentIndex: indexWidgetProvider.mainIndex,
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
          indexWidgetProvider.mainIndex = index;
          //不传入路由context和样式，走工作区路由
          indexWidgetProvider.push(mainViews[index], push: false);
        },
      );
    });
    return bottomNavigationBar;
  }

  @override
  Widget build(BuildContext context) {
    var bottomNavigationBar = _createBottomBar(context);
    return bottomNavigationBar;
  }
}
