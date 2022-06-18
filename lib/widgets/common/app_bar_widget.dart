import 'package:colla_chat/provider/index_views.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/app_data.dart';

///工作区的顶部栏AppBar，定义了回退按钮
class AppBarWidget extends StatelessWidget {
  final String title;
  final List<String>? rightActions;
  final Function(int index)? rightCallBack;
  final Widget? bottom;
  final bool withBack;
  final Function? backCallBack;

  const AppBarWidget(
      {Key? key,
      this.title = '',
      this.rightActions,
      this.rightCallBack,
      this.bottom,
      this.withBack = false,
      this.backCallBack})
      : super(key: key);

  Widget? backButton(BuildContext context) {
    Widget? backButton;
    bool withBack = this.withBack;
    if (withBack) {
      backButton = IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.white),
        onPressed: () {
          final backCallBack = this.backCallBack;
          if (backCallBack != null) {
            backCallBack();
          } else {
            var indexViewProvider =
                Provider.of<IndexViewProvider>(context, listen: false);
            indexViewProvider.pop();
          }
        },
      );
    }
    return backButton;
  }

  PopupMenuButton<int>? rightAction() {
    PopupMenuButton<int>? menus;
    var rightActions = this.rightActions;
    if (rightActions != null && rightActions.isNotEmpty) {
      List<PopupMenuItem<int>> items = [];
      int i = 0;
      for (var rightAction in rightActions) {
        var item = PopupMenuItem<int>(
          value: i,
          child: Text(rightAction),
        );
        items.add(item);
        ++i;
      }
      menus = PopupMenuButton<int>(
        itemBuilder: (BuildContext context) {
          return items;
        },
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onSelected: (int index) {
          if (rightCallBack != null) {
            rightCallBack!(index);
          }
        },
      );
    }

    return menus;
  }

  @override
  Widget build(BuildContext context) {
    var listTiles = <Widget>[];
    var listTile = ListTile(
      title: Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white)),
      tileColor: appDataProvider.themeData?.colorScheme.primary,
      leading: backButton(context),
      trailing: rightAction(),
    );
    listTiles.add(listTile);
    var bottom = this.bottom;
    if (bottom != null) {
      listTiles.add(Expanded(child: bottom));
    }
    return Column(
      children: listTiles,
    );
  }
}
