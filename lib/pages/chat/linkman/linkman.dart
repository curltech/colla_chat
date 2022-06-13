import 'package:colla_chat/pages/chat/linkman/linkman_add.dart';
import 'package:colla_chat/provider/linkman_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/localization.dart';
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

  @override
  Widget build(BuildContext context) {
    var stack = IndexedStack(
      index: _currentIndex,
      children: _children,
    );
    var appBar = AppBar(
      title: Text(AppLocalizations.t('Linkman')),
      actions: [
        IconButton(
            onPressed: () async {
              setState(() {
                _currentIndex = 0;
              });
            },
            icon: const Icon(Icons.person),
            tooltip: AppLocalizations.t('Linkman')),
        IconButton(
          onPressed: () async {
            setState(() {
              _currentIndex = 1;
            });
          },
          icon: const Icon(Icons.person_add),
          tooltip: AppLocalizations.t('Add'),
        ),
      ],
    );
    return ChangeNotifierProvider.value(
      value: LinkmenDataProvider(),
      child: Scaffold(
          appBar: appBar,
          body: Center(
              child: SizedBox(
            width: 380,
            height: 500,
            child: stack,
          ))),
    );
  }
}
