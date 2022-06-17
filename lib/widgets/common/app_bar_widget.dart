import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../provider/app_data.dart';

///工作区的顶部栏AppBar，定义了回退按钮
class AppBarWidget extends StatelessWidget {
  final String title;
  final List<Widget> rightActions;
  final Widget? bottom;
  final Function? backCallBack;

  const AppBarWidget(
      {Key? key,
      this.title = '',
      this.rightActions = const <Widget>[],
      this.bottom,
      this.backCallBack})
      : super(key: key);

  Widget? backButton() {
    Widget? backButton;
    final backCallBack = this.backCallBack;
    if (backCallBack != null) {
      backButton = IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          final backCallBack = this.backCallBack;
          if (backCallBack != null) {
            backCallBack();
          }
        },
      );
    }
    return backButton;
  }

  @override
  Widget build(BuildContext context) {
    var listTiles = <Widget>[];
    var listTile = ListTile(
      title: Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white)),
      tileColor: appDataProvider.themeData?.colorScheme.primary,
      leading: backButton(),
      // trailing: Row(
      //   children: rightActions,
      // )
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
