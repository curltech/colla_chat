import 'package:colla_chat/pages/chat/linkman/linkman_add.dart';
import 'package:colla_chat/provider/linkman_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization.dart';
import '../../../provider/app_data.dart';
import 'linkman_widget.dart';

//好友页面
class Linkman extends StatefulWidget {
  const Linkman({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanState();
}

class _LinkmanState extends State<Linkman> {
  int _currentIndex = 0;
  late List<Widget> _children;

  @override
  void initState() {
    super.initState();
    // 初始化子项集合
    var linkmanWidget = const LinkmanWidget();
    var linkmanAddWidget = const LinkmanAddWidget();
    _children = [
      linkmanWidget,
      linkmanAddWidget,
    ];
  }

  PopupMenuButton _popupMenuButton(BuildContext context) {
    return PopupMenuButton<int>(
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            child: Text("Linkman"),
            value: 0,
          ),
          PopupMenuItem(
            child: Text("LinkmanAdd"),
            value: 1,
          ),
        ];
      },
      icon: Icon(
        Icons.add_box_rounded,
        color: Provider.of<AppDataProvider>(context)
            .themeData
            ?.colorScheme
            .primary,
      ),
      onSelected: (dynamic item) {
        setState(() {
          _currentIndex = item;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var stack = IndexedStack(
      index: _currentIndex,
      children: _children,
    );
    var toolBar = ListTile(
      title: Text(AppLocalizations.t('Linkman'),
          style: TextStyle(
              color: Provider.of<AppDataProvider>(context)
                  .themeData
                  ?.colorScheme
                  .primary)),
      trailing: _popupMenuButton(context),
    );
    return ChangeNotifierProvider.value(
      value: LinkmenDataProvider(),
      child: Column(
        children: [toolBar, Expanded(child: stack)],
      ),
    );
  }
}
