import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/qrcode_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/routers/routes.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IndexGridViewWidget extends StatefulWidget with TileDataMixin {
  const IndexGridViewWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _IndexGridViewWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'index_grid_view';

  @override
  IconData get iconData => Icons.grid_view;

  @override
  String get title => 'Index Grid View';
}

class _IndexGridViewWidgetState extends State<IndexGridViewWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildIndexViews(BuildContext context, BoxConstraints constraints) {
    List<TileDataMixin> indexViews = indexWidgetProvider.views.sublist(6);
    int crossAxisCount = 1;
    if (indexViews.length > 1) {
      crossAxisCount = 2;
    } else if (indexViews.isEmpty) {
      return Container();
    }

    return GridView.builder(
        itemCount: indexViews.length,
        //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            //横轴元素个数
            crossAxisCount: crossAxisCount,
            //纵轴间距
            mainAxisSpacing: 1.0,
            //横轴间距
            crossAxisSpacing: 1.0,
            //子组件宽高长度比例
            childAspectRatio: 1),
        itemBuilder: (BuildContext context, int index) {
          //Widget Function(BuildContext context, int index)
          return indexViews[index];
        });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return _buildIndexViews(context, constraints);
    });
  }
}
