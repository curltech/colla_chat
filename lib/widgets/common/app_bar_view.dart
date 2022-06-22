import 'package:flutter/material.dart';

import 'app_bar_widget.dart';
import 'data_listtile.dart';

///工作区的标准视图，包裹了顶部栏AppBarWidget和一个包裹了child
class AppBarView extends StatelessWidget {
  final String title;
  final Widget child;
  final List<String>? rightActions;
  final List<Widget>? rightWidgets;
  final Function(int index)? rightCallBack;
  final Widget? bottom;
  final bool withBack;
  //指定回退路由样式，不指定则系统判断
  final RouteStyle? backRouteStyle;
  final Function? backCallBack;

  const AppBarView(
      {Key? key,
      required this.title,
      required this.child,
      this.rightActions,
      this.rightWidgets,
      this.rightCallBack,
      this.bottom,
      this.withBack = false,
      this.backRouteStyle,
      this.backCallBack})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        borderOnForeground: false,
        elevation: 0.0,
        child: Column(children: <Widget>[
          AppBarWidget(
              title: title,
              rightActions: rightActions,
              rightWidgets: rightWidgets,
              bottom: bottom,
              withBack: withBack,
              backRouteStyle: backRouteStyle,
              backCallBack: backCallBack,
              rightCallBack: rightCallBack),
          child,
        ]));
  }
}
