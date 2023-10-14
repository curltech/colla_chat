import 'package:colla_chat/pages/stock/me/add_share_widget.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/pages/stock/setting/refresh_stock_widget.dart';
import 'package:colla_chat/pages/stock/setting/update_stock_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

/// 股票功能主页面，带有路由回调函数
class StockMainWidget extends StatelessWidget with TileDataMixin {
  final ShareSelectionWidget shareSelectionWidget = ShareSelectionWidget();
  final AddShareWidget addShareWidget = AddShareWidget();
  final RefreshStockWidget refreshStockWidget = RefreshStockWidget();
  final UpdateStockWidget updateStockWidget = UpdateStockWidget();

  StockMainWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(shareSelectionWidget);
    indexWidgetProvider.define(addShareWidget);
    indexWidgetProvider.define(refreshStockWidget);
    indexWidgetProvider.define(updateStockWidget);
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
    Map<TileData, List<TileData>> tileData = {};
    final List<TileData> meTileData = TileData.from([
      shareSelectionWidget,
      addShareWidget,
    ]);
    for (var tile in meTileData) {
      tile.dense = false;
      tile.selected = false;
    }
    tileData[TileData(title: 'Me')] = meTileData;
    final List<TileData> settingTileData = TileData.from([
      refreshStockWidget,
      updateStockWidget,
    ]);
    for (var tile in settingTileData) {
      tile.dense = false;
      tile.selected = false;
    }
    tileData[TileData(title: 'Me')] = meTileData;
    tileData[TileData(title: 'Setting')] = settingTileData;
    Widget child = GroupDataListView(tileData: tileData);
    var stockMain = AppBarView(title: title, child: child);

    return stockMain;
  }
}
