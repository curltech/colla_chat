import 'package:flutter/material.dart';

import 'app_bar_widget.dart';

///工作区的标准视图，包裹了顶部栏AppBarWidget和一个包裹了child的滚动视图
class AppBarView extends StatelessWidget {
  final String title;
  final Widget child;

  const AppBarView({Key? key, required this.title, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: title),
      body: SingleChildScrollView(child: child),
    );
  }
}
