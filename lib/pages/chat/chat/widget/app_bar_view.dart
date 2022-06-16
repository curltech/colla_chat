import 'package:flutter/material.dart';

import 'app_bar_widget.dart';

///工作区的标准视图，包裹了顶部栏AppBarWidget和一个包裹了child的滚动视图
class AppBarView extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? titleWidget;
  final String? leadingImage;
  final Widget? leadingWidget;
  final List<Widget>? rightActions;
  final Widget? bottom;
  final TabController? tabController;

  const AppBarView(
      {Key? key,
      required this.title,
      required this.child,
      this.titleWidget,
      this.leadingImage,
      this.leadingWidget,
      this.rightActions,
      this.bottom,
      this.tabController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      AppBarWidget(
          title: title,
          titleWidget: titleWidget,
          leadingImage: leadingImage,
          leadingWidget: leadingWidget,
          rightActions: rightActions,
          bottom: bottom,
          tabController: tabController),
      SingleChildScrollView(child: child),
    ]);
  }
}
