import 'package:colla_chat/pages/stock/me/add_share_widget.dart';
import 'package:colla_chat/pages/stock/me/event_filter_widget.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/pages/stock/setting/refresh_stock_widget.dart';
import 'package:colla_chat/pages/stock/setting/update_stock_widget.dart';
import 'package:colla_chat/pages/stock/trade/in_out_event_widget.dart';
import 'package:colla_chat/pages/stock/value/performance_widget.dart';
import 'package:colla_chat/pages/stock/value/qperformance_widget.dart';
import 'package:colla_chat/pages/stock/value/qstat_widget.dart';
import 'package:colla_chat/pages/stock/value/stat_score_widget.dart';
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
  final InoutEventWidget inoutEventWidget = InoutEventWidget();
  final EventFilterWidget eventFilterWidget = EventFilterWidget();
  final PerformanceWidget performanceWidget = PerformanceWidget();
  final QPerformanceWidget qperformanceWidget = QPerformanceWidget();
  final QStatWidget qstatWidget = QStatWidget();
  final StatScoreWidget statScoreWidget = StatScoreWidget();

  StockMainWidget({super.key}) {
    indexWidgetProvider.define(shareSelectionWidget);
    indexWidgetProvider.define(addShareWidget);
    indexWidgetProvider.define(refreshStockWidget);
    indexWidgetProvider.define(updateStockWidget);
    indexWidgetProvider.define(inoutEventWidget);
    indexWidgetProvider.define(eventFilterWidget);
    indexWidgetProvider.define(performanceWidget);
    indexWidgetProvider.define(qperformanceWidget);
    indexWidgetProvider.define(qstatWidget);
    indexWidgetProvider.define(statScoreWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'stock_main';

  @override
  IconData get iconData => Icons.candlestick_chart;

  @override
  String get title => 'Stock';

  @override
  Widget build(BuildContext context) {
    Map<TileData, List<TileData>> tileData = {};
    final List<TileData> meTileData = TileData.from([
      shareSelectionWidget,
      addShareWidget,
      eventFilterWidget,
    ]);
    for (var tile in meTileData) {
      tile.dense = false;
      tile.selected = false;
    }
    tileData[TileData(title: 'Me', selected: true)] = meTileData;

    final List<TileData> valueTileData = TileData.from([
      performanceWidget,
      qperformanceWidget,
      qstatWidget,
      statScoreWidget,
    ]);
    for (var tile in valueTileData) {
      tile.dense = false;
      tile.selected = false;
    }
    tileData[TileData(title: 'Value', selected: true)] = valueTileData;

    List<TileDataMixin> mixins = [
      refreshStockWidget,
      updateStockWidget,
    ];

    final List<TileData> settingTileData = TileData.from(mixins);
    for (var tile in settingTileData) {
      tile.dense = false;
      tile.selected = false;
    }
    tileData[TileData(
      title: 'Setting',
      selected: true,
    )] = settingTileData;

    Widget stockMain = GroupDataListView(tileData: tileData);

    return stockMain;
  }
}
