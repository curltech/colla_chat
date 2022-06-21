import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/app_data_provider.dart';
import 'index_widget_controller.dart';

///mobile底边栏，用于指示当前主页面
class BottomBar extends StatefulWidget {
  BottomBar({Key? key}) : super(key: key);

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
    Widget bottomNavigationBar = Consumer<IndexWidgetController>(
        builder: (context, indexWidgetController, child) {
      return BottomNavigationBar(
        //底部按钮，移动版才有
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat),
              label: indexWidgetController.getLabel(0)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.contacts),
              label: indexWidgetController.getLabel(1)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.wifi_channel),
              label: indexWidgetController.getLabel(2)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: indexWidgetController.getLabel(3)),
        ],
        currentIndex: indexWidgetController.mainIndex,
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
          indexWidgetController.mainIndex = index;
          indexWidgetController.push(widgetPosition[index]);
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
