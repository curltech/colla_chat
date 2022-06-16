import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../provider/app_data.dart';

///工作区的顶部栏AppBar，定义了回退按钮
class AppBarWidget extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final String? leadingImage;
  final Widget? leadingWidget;
  final List<Widget>? rightActions;
  final Widget? bottom;
  final TabController? tabController;

  const AppBarWidget(
      {Key? key,
      this.title = '',
      this.titleWidget,
      this.leadingImage,
      this.leadingWidget,
      this.rightActions,
      this.bottom,
      this.tabController})
      : super(key: key);

  Widget? leading(BuildContext context) {
    var leadingWidgets = <Widget>[];
    if (tabController != null) {
      leadingWidgets.add(Icon(CupertinoIcons.back,
          color: appDataProvider.themeData?.colorScheme.primary));
    }
    final leadingImage = this.leadingImage;
    if (leadingImage != null) {
      leadingWidgets
          .add(Image.memory(Uint8List.fromList(leadingImage.codeUnits)));
    }
    if (leadingWidget != null) {
      leadingWidgets.add(leadingWidget!);
    }
    return InkWell(
      child: Row(
        children: leadingWidgets,
      ),
      onTap: () {
        final tabController = this.tabController;
        if (tabController != null) {
          tabController.index = 0;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(title,
              style: TextStyle(
                  color: appDataProvider.themeData?.colorScheme.primary)),
          tileColor: appDataProvider.themeData?.colorScheme.primary,
          //leading: leading(context),
          // trailing: Row(
          //   children: rightActions!,
          // )
        ),
        //Expanded(child: bottom!),
      ],
    );
  }
}
