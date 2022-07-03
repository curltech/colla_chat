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
  final List<String>? rightActions;
  final List<Icon>? rightIcons;
  final Function(int index)? rightCallBack;
  final PreferredSizeWidget? bottom;
  final Widget child;

  const AppBarView({
    Key? key,
    this.withLeading = false,
    this.leadingCallBack,
    required this.title,
    this.centerTitle = false,
    this.rightWidgets,
    this.rightActions,
    this.rightIcons,
    this.rightCallBack,
    this.bottom,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<IndexWidgetProvider>(
        builder: (context, indexWidgetProvider, child) {
      return Scaffold(
        appBar: AppBarWidget.build(context,
            withLeading: withLeading,
            leadingCallBack: leadingCallBack,
            title: title,
            centerTitle: centerTitle,
            rightWidgets: rightWidgets,
            rightActions: rightActions,
            rightIcons: rightIcons,
            bottom: bottom,
            rightCallBack: rightCallBack),
        body: this.child,
      );
    });
  }
}
