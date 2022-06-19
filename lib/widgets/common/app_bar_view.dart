import 'package:flutter/material.dart';

import 'app_bar_widget.dart';

///工作区的标准视图，包裹了顶部栏AppBarWidget和一个包裹了child
class AppBarView extends StatelessWidget {
  final String title;
  final Widget child;
  final List<String>? rightActions;
  final Function(int index)? rightCallBack;
  final Widget? bottom;
  final bool withBack;
  final Function? backCallBack;

  const AppBarView(
      {Key? key,
      required this.title,
      required this.child,
      this.rightActions,
      this.rightCallBack,
      this.bottom,
      this.withBack = false,
      this.backCallBack})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      AppBarWidget(
          title: title,
          rightActions: rightActions,
          bottom: bottom,
          withBack: withBack,
          backCallBack: backCallBack,
          rightCallBack: rightCallBack),
      child,
    ]);
  }
}
