import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_bar_widget.dart';

///工作区的标准视图，包裹了顶部栏AppBarWidget和一个包裹了child
class AppBarView extends StatelessWidget {
  final bool withLeading;

  //指定回退路由样式，不指定则系统判断
  final Function? leadingCallBack;
  final String title;
  final bool centerTitle;
  //右边按钮
  final List<Widget>? rightWidgets;
  //右边下拉菜单
  final List<AppBarPopupMenu>? rightPopupMenus;
  final PreferredSizeWidget? bottom;
  final Widget child;

  const AppBarView({
    Key? key,
    this.withLeading = false,
    this.leadingCallBack,
    required this.title,
    this.centerTitle = true,
    this.rightWidgets,
    this.rightPopupMenus,
    this.bottom,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      return Column(children: [
        AppBarWidget.build(
          context,
          withLeading: withLeading,
          leadingCallBack: leadingCallBack,
          title: title,
          centerTitle: centerTitle,
          rightWidgets: rightWidgets,
          rightPopupMenus: rightPopupMenus,
          bottom: bottom,
        ),
        Expanded(child: this.child),
      ]);
    });
  }
}
