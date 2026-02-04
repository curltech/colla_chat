import 'package:colla_chat/pages/stock/me/add_share_widget.dart';
import 'package:colla_chat/pages/stock/me/event_filter_widget.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/pages/stock/me/stock_dayline_widget.dart';
import 'package:colla_chat/pages/stock/me/stock_line_chart_widget.dart';
import 'package:colla_chat/pages/stock/setting/refresh_stock_widget.dart';
import 'package:colla_chat/pages/stock/setting/update_stock_widget.dart';
import 'package:colla_chat/pages/stock/trade/in_out_event_widget.dart';
import 'package:colla_chat/pages/stock/value/performance_widget.dart';
import 'package:colla_chat/pages/stock/value/qperformance_widget.dart';
import 'package:colla_chat/pages/stock/value/qstat_widget.dart';
import 'package:colla_chat/pages/stock/value/stat_score_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_adaptive_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

class StockController {
  final ShareSelectionWidget shareSelectionWidget = ShareSelectionWidget();
  final AddShareWidget addShareWidget = AddShareWidget();
  final StockLineChartWidget stockLineChartWidget = StockLineChartWidget();
  final RefreshStockWidget refreshStockWidget = RefreshStockWidget();
  final UpdateStockWidget updateStockWidget = UpdateStockWidget();
  final InoutEventWidget inoutEventWidget = InoutEventWidget();
  final EventFilterWidget eventFilterWidget = EventFilterWidget();
  final DayLineWidget dayLineWidget = DayLineWidget();
  final PerformanceWidget performanceWidget = PerformanceWidget();
  final QPerformanceWidget qperformanceWidget = QPerformanceWidget();
  final QStatWidget qstatWidget = QStatWidget();
  final StatScoreWidget statScoreWidget = StatScoreWidget();
  final Map<DataTile, List<DataTile>> stockTileData = {};
  final Map<DataTile, List<DataTileMixin>> stockWidgets = {};
  late final ValueNotifier<DataTileMixin> currentWidget =
      ValueNotifier<DataTileMixin>(shareSelectionWidget);
  final List<DataTileMixin> stockStacks = [];

  StockController() {
    init();
  }

  void init() {
    final List<DataTileMixin> meWidgets = [
      shareSelectionWidget,
      addShareWidget,
      dayLineWidget,
      eventFilterWidget,
      inoutEventWidget
    ];
    final List<DataTile> meDataTiles = DataTile.from(meWidgets);
    DataTile meDataTile = DataTile(title: 'Me', selected: true);
    stockTileData[meDataTile] = meDataTiles;
    stockWidgets[meDataTile] = meWidgets;
    meWidgets.add(stockLineChartWidget);

    final List<DataTileMixin> valueWidgets = [
      performanceWidget,
      qperformanceWidget,
      qstatWidget,
      statScoreWidget,
    ];
    final List<DataTile> valueDataTiles = DataTile.from(valueWidgets);
    DataTile valueDataTile = DataTile(title: 'Value', selected: true);
    stockTileData[valueDataTile] = valueDataTiles;
    stockWidgets[valueDataTile] = valueWidgets;

    final List<DataTileMixin> settingWidgets = [
      refreshStockWidget,
      updateStockWidget,
    ];
    final List<DataTile> settingDataTiles = DataTile.from(settingWidgets);
    DataTile settingDataTile = DataTile(
      title: 'Setting',
      selected: true,
    );
    stockTileData[settingDataTile] = settingDataTiles;
    stockWidgets[settingDataTile] = settingWidgets;
  }

  void push(String name) {
    for (var stockDataTiles in stockWidgets.entries) {
      var stockWidgets = stockDataTiles.value;
      for (var stockWidget in stockWidgets) {
        if (stockWidget.routeName == name) {
          stockStacks.add(currentWidget.value);
          currentWidget.value = stockWidget;
          return;
        }
      }
    }
  }

  void pop() {
    if (stockStacks.isNotEmpty) {
      DataTileMixin last = stockStacks.removeLast();
      currentWidget.value = last;
    }
  }
}

final StockController stockController = StockController();

/// 股票功能主页面，带有路由回调函数
class StockMainWidget extends StatelessWidget with DataTileMixin {
  StockMainWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'stock';

  @override
  IconData get iconData => Icons.candlestick_chart;

  @override
  String get title => 'Stock';

  @override
  Widget build(BuildContext context) {
    Widget stockMain = ValueListenableBuilder(
        valueListenable: stockController.currentWidget,
        builder: (BuildContext context, Widget value, Widget? child) {
          // String title = this.title + currentBody.value.title ?? '';
          return AppBarAdaptiveView(
              title: title,
              withLeading: true,
              main: GroupDataListView(
                tileData: stockController.stockTileData,
                onTap: (int index, String title,
                    {DataTile? group, String? subtitle}) async {
                  stockController.currentWidget.value =
                      stockController.stockWidgets[group]?[index] ??
                          stockController.shareSelectionWidget;

                  return false;
                },
              ),
              body: stockController.currentWidget.value);
        });

    return stockMain;
  }
}
