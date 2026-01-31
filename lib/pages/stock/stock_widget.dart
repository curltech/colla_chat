import 'package:colla_chat/pages/stock/me/add_share_widget.dart';
import 'package:colla_chat/pages/stock/me/event_filter_widget.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/pages/stock/me/stock_dayline_widget.dart';
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

/// 股票功能主页面，带有路由回调函数
class StockMainWidget extends StatelessWidget with DataTileMixin {
  final ShareSelectionWidget shareSelectionWidget = ShareSelectionWidget();
  final AddShareWidget addShareWidget = AddShareWidget();
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
  final Map<DataTile, List<Widget>> stockWidgets = {};
  late final ValueNotifier<Widget> currentBody =
      ValueNotifier<Widget>(shareSelectionWidget);

  StockMainWidget({super.key}) {
    init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'stock';

  @override
  IconData get iconData => Icons.candlestick_chart;

  @override
  String get title => 'Stock';

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

  @override
  Widget build(BuildContext context) {
    Widget stockMain = ValueListenableBuilder(
        valueListenable: currentBody,
        builder: (BuildContext context, Widget value, Widget? child) {
          // String title = this.title + currentBody.value.title ?? '';
          return AppBarAdaptiveView(
              title: title,
              withLeading: true,
              main: GroupDataListView(
                tileData: stockTileData,
                onTap: (int index, String title,
                    {DataTile? group, String? subtitle}) async {
                  currentBody.value =
                      stockWidgets[group]?[index] ?? shareSelectionWidget;
                  return null;
                },
              ),
              body: currentBody.value);
        });

    return stockMain;
  }
}
