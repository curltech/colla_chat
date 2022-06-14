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
  String _key = '';
  late List<Widget> _children;
  LinkmenDataProvider _linkmenDataProvider = LinkmenDataProvider();

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

  PopupMenuButton _popupMenuButton() {
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
      trailing: _popupMenuButton(),
    );
    var searchBar = Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.0),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: AppLocalizations.t('search'),
            suffixIcon: Icon(Icons.search),
          ),
          initialValue: _key,
          onChanged: (String val) {
            setState(() {
              _key = val;
            });
          },
          onTap: () {
            logger.i('search $_key');
          },
        ));
    return ChangeNotifierProvider.value(
      value: _linkmenDataProvider,
      child: Column(
        children: [toolBar, searchBar, Expanded(child: stack)],
      ),
    );
  }
}
