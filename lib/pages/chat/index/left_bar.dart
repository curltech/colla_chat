import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

///横屏左边栏，用于指示当前主页面
class LeftBar extends StatefulWidget {
  final bool normal;

  const LeftBar({Key? key, this.normal = true}) : super(key: key);

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

  Widget _createLeftBarItem(
      BuildContext context, IndexWidgetProvider indexWidgetProvider,
      {required int index, String? tooltip, required Icon icon}) {
    bool current = indexWidgetProvider.currentMainIndex == index;

    List<Widget> children = [icon];
    String label = indexWidgetProvider.getLabel(index);
    if (widget.normal) {
      children.add(const SizedBox(
        height: 0.0,
      ));
      children.add(CommonAutoSizeText(
        label,
        style: TextStyle(
            color: current ? myself.primary : Colors.grey,
            fontSize: current ? AppFontSize.mdFontSize : AppFontSize.smFontSize,
            fontWeight: current ? FontWeight.bold : FontWeight.normal),
      ));
    }
    Widget item = IconButton(
      iconSize: current ? AppIconSize.mdSize : AppIconSize.smSize,
      color: current ? myself.primary : Colors.grey,
      onPressed: () {
        indexWidgetProvider.currentMainIndex = index;
      },
      icon: Column(children: children),
      tooltip: tooltip,
    );

    return item;
  }

  Widget _createLeftBar(BuildContext context) {
    Widget leftNavigationBar = Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      return SizedBox(
          width: appDataProvider.leftBarWidth,
          child: Column(
            children: [
              const SizedBox(
                height: 25.0,
              ),
              _createLeftBarItem(
                context,
                indexWidgetProvider,
                index: 0,
                icon: const Icon(Icons.chat),
              ),
              const SizedBox(
                height: 25.0,
              ),
              _createLeftBarItem(
                context,
                indexWidgetProvider,
                index: 1,
                icon: const Icon(Icons.contacts),
              ),
              const SizedBox(
                height: 25.0,
              ),
              _createLeftBarItem(
                context,
                indexWidgetProvider,
                index: 2,
                icon: const Icon(Icons.wifi_channel),
              ),
              const SizedBox(
                height: 25.0,
              ),
              // _createLeftBarItem(context,indexWidgetProvider,
              //      index: 0,
              //     icon: const Icon(Icons.candlestick_chart),),
              _createLeftBarItem(
                context,
                indexWidgetProvider,
                index: 3,
                icon: const Icon(Icons.person),
              ),
            ],
          ));
    });
    return leftNavigationBar;
  }

  @override
  Widget build(BuildContext context) {
    var leftNavigationBar = Card(
        elevation: 0.0,
        margin: EdgeInsets.zero,
        shape: const ContinuousRectangleBorder(),
        child: _createLeftBar(context));

    return leftNavigationBar;
  }
}
