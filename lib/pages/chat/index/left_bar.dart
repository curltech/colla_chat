import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/index_widget_provider.dart';

///destop右边栏，用于指示当前主页面
class LeftBar extends StatefulWidget {
  const LeftBar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LeftBarState();
  }
}

class _LeftBarState extends State<LeftBar> {
  @override
  initState() {
    super.initState();
  }

  Widget _createLeftBar(BuildContext context) {
    return Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      return SizedBox(
        width: indexWidgetProvider.leftBarWidth,
        child: ListView(
          children: <Widget>[
            ListTile(
                iconColor: indexWidgetProvider.getIconColor(0),
                title: const Icon(Icons.chat),
                subtitle: Text(
                  indexWidgetProvider.getLabel(0),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: indexWidgetProvider.getIconColor(0)),
                ),
                onTap: () {
                  indexWidgetProvider.mainIndex = 0;
                  //不传入路由context和样式，走工作区路由
                  indexWidgetProvider.push(workspaceViews[0]);
                }),
            ListTile(
                iconColor: indexWidgetProvider.getIconColor(1),
                title: const Icon(Icons.contacts),
                subtitle: Text(
                  indexWidgetProvider.getLabel(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: indexWidgetProvider.getIconColor(1)),
                ),
                onTap: () {
                  indexWidgetProvider.mainIndex = 1;
                  indexWidgetProvider.push(workspaceViews[1]);
                }),
            ListTile(
                iconColor: indexWidgetProvider.getIconColor(2),
                title: const Icon(Icons.wifi_channel),
                subtitle: Text(
                  indexWidgetProvider.getLabel(2),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: indexWidgetProvider.getIconColor(2)),
                ),
                onTap: () {
                  indexWidgetProvider.mainIndex = 2;
                  indexWidgetProvider.push(workspaceViews[2]);
                }),
            ListTile(
                iconColor: indexWidgetProvider.getIconColor(3),
                title: const Icon(Icons.person),
                subtitle: Text(
                  indexWidgetProvider.getLabel(3),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: indexWidgetProvider.getIconColor(3)),
                ),
                onTap: () {
                  indexWidgetProvider.mainIndex = 3;
                  indexWidgetProvider.push(workspaceViews[3]);
                }),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var leftBar = _createLeftBar(context);

    return leftBar;
  }
}
