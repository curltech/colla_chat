import 'package:colla_chat/pages/stock/stock_widget.dart';
import 'package:colla_chat/plugin/chart/k_chart/k_chart_plus_widget.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_tool_panel_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

class StockLineChartWidget extends StatelessWidget with DataTileMixin {
  StockLineChartWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'stockline_chart';

  @override
  IconData get iconData => Icons.insert_chart_outlined;

  @override
  String get title => 'StockLineChart';

  final KChartPlusController kChartPlusController = KChartPlusController();

  @override
  Widget build(BuildContext context) {
    Widget titleWidget = Obx(
      () {
        KlineController? klineController = multiKlineController.klineController;
        if (klineController == null) {
          return AutoSizeText(title);
        }
        return AutoSizeText(
            '${klineController.tsCode}-${klineController.name}');
      },
    );
    return AppBarView(
      titleWidget: titleWidget,
      helpPath: routeName,
      isAppBar: false,
      withLeading: true,
      leadingCallBack: () {
        stockController.pop();
      },
      child: Center(
          child: Column(children: [
        KlineToolPanelWidget(
          kChartPlusController: kChartPlusController,
        ),
        Expanded(
            child: KChartPlusWidget(
          kChartPlusController: kChartPlusController,
        )),
      ])),
    );
  }
}
