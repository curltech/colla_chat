import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 数据存储管理功能主页面，带有路由回调函数
class DataStoreMainWidget extends StatelessWidget with TileDataMixin {
  DataStoreMainWidget({super.key}) {}

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'datastore_main';

  @override
  IconData get iconData => Icons.dataset_outlined;

  @override
  String get title => 'DataStore';

  TreeViewController? treeViewController;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
