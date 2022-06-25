import 'package:flutter/material.dart';

mixin TileDataMixin on Widget {
  //指示图标
  Icon get icon;

  //标题
  String get title;

  //路由名称
  String get routeName;

  //界面上是否有前导回退按钮
  bool get withLeading;
}
