import 'package:colla_chat/pages/stock/my_selection_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 股票功能主页面，带有路由回调函数
class StockMainWidget extends StatelessWidget with TileDataMixin {
  final ShareSelectionWidget shareSelectionWidget = ShareSelectionWidget();

  late final List<TileData> meTileData;

  StockMainWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(shareSelectionWidget);
    List<TileDataMixin> mixins = [
      shareSelectionWidget,
    ];
    meTileData = TileData.from(mixins);
    for (var tile in meTileData) {
      tile.dense = false;
      tile.selected = false;
    }
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'stock_main';

  @override
  IconData get iconData => Icons.waterfall_chart;

  @override
  String get title => 'Stock';

  @override
  Widget build(BuildContext context) {
    Widget child = DataListView(tileData: meTileData);
    var stockMain = AppBarView(title: title, child: child);

    return stockMain;
  }
}
