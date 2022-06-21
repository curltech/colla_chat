import 'package:flutter/material.dart';

import 'index_widget_controller.dart';

///destop右边栏，用于指示当前主页面
class LeftBar extends StatefulWidget {
  IndexWidgetController indexWidgetController = IndexWidgetController.instance;

  LeftBar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LeftBarState();
  }
}

class _LeftBarState extends State<LeftBar> {
  @override
  initState() {
    super.initState();
    widget.indexWidgetController.addListener(() {
      setState(() {});
    });
  }

  Widget _createLeftBar(BuildContext context) {
    var indexWidgetController = widget.indexWidgetController;
    return SizedBox(
      width: 90.0,
      child: ListView(
        children: <Widget>[
          ListTile(
              iconColor: indexWidgetController.getIconColor(0),
              title: Icon(Icons.chat),
              subtitle: Text(
                indexWidgetController.getLabel(0),
                textAlign: TextAlign.center,
                style: TextStyle(color: indexWidgetController.getIconColor(0)),
              ),
              onTap: () {
                indexWidgetController.mainIndex = 0;
                indexWidgetController.push(widgetPosition[0]);
              }),
          ListTile(
              iconColor: indexWidgetController.getIconColor(1),
              title: Icon(Icons.contacts),
              subtitle: Text(
                indexWidgetController.getLabel(1),
                textAlign: TextAlign.center,
                style: TextStyle(color: indexWidgetController.getIconColor(1)),
              ),
              onTap: () {
                indexWidgetController.mainIndex = 1;
                indexWidgetController.push(widgetPosition[1]);
              }),
          ListTile(
              iconColor: indexWidgetController.getIconColor(2),
              title: Icon(Icons.wifi_channel),
              subtitle: Text(
                indexWidgetController.getLabel(2),
                textAlign: TextAlign.center,
                style: TextStyle(color: indexWidgetController.getIconColor(2)),
              ),
              onTap: () {
                indexWidgetController.mainIndex = 2;
                indexWidgetController.push(widgetPosition[2]);
              }),
          ListTile(
              iconColor: indexWidgetController.getIconColor(3),
              title: Icon(Icons.person),
              subtitle: Text(
                indexWidgetController.getLabel(3),
                textAlign: TextAlign.center,
                style: TextStyle(color: indexWidgetController.getIconColor(3)),
              ),
              onTap: () {
                indexWidgetController.mainIndex = 3;
                indexWidgetController.push(widgetPosition[3]);
              }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var leftBar = _createLeftBar(context);

    return leftBar;
  }
}
