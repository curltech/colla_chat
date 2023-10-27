import 'package:colla_chat/entity/stock/performance.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/stock_line_chart_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/performance.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';

/// 自选股当前日线的控制器
final DataListController<Performance> performanceController =
    DataListController<Performance>();

///自选股和分组的查询界面
class PerformanceWidget extends StatefulWidget with TileDataMixin {
  PerformanceWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PerformanceWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'performance';

  @override
  IconData get iconData => Icons.bar_chart;

  @override
  String get title => 'Performance';
}

class _PerformanceWidgetState extends State<PerformanceWidget>
    with TickerProviderStateMixin {
  late final List<PlatformDataColumn> performanceDataColumns = [
    PlatformDataColumn(
      label: '股票代码',
      name: 'ts_code',
      width: 80,
    ),
    PlatformDataColumn(
      label: '股票名',
      name: 'name',
      width: 80,
    ),
    PlatformDataColumn(
      label: '交易日期',
      name: 'trade_date',
      width: 90,
    ),
    PlatformDataColumn(
      label: '收盘价',
      name: 'close',
      dataType: DataType.double,
      align: TextAlign.end,
      width: 70,
    ),
    PlatformDataColumn(
      label: '涨幅',
      name: 'pct_chg_close',
      dataType: DataType.percentage,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.end,
      width: 70,
    ),
    PlatformDataColumn(
      label: '量变化',
      name: 'pct_chg_vol',
      dataType: DataType.percentage,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.end,
      width: 70,
    ),
    PlatformDataColumn(
      label: '换手率',
      name: 'turnover',
      dataType: DataType.double,
      align: TextAlign.end,
      width: 70,
    ),
    PlatformDataColumn(
        label: '',
        name: 'action',
        inputType: InputType.custom,
        buildSuffix: _buildActionWidget),
  ];
  final TextEditingController _searchTextController = TextEditingController();

  @override
  initState() {
    performanceController.addListener(_updatePerformance);
    super.initState();
  }

  _updatePerformance() {
    setState(() {});
  }

  Widget _buildActionWidget(int index, dynamic dayLine) {
    Widget actionWidget = Row(
      children: [
        const SizedBox(
          width: 10,
        ),
        IconButton(
          onPressed: () async {
            String tsCode = dayLine.tsCode;
            Share? share = await shareService.findShare(tsCode);
            String name = share?.name ?? '';
            multiStockLineController.put(tsCode, name);
            indexWidgetProvider.push('stockline_chart');
          },
          icon: const Icon(
            Icons.filter,
            color: Colors.yellow,
          ),
          tooltip: AppLocalizations.t('StockLineChart'),
        )
      ],
    );
    return actionWidget;
  }

  _refresh(String key) async {
    List<Performance> performances =
        await remotePerformanceService.sendFindLatest(key);
    performanceController.replaceAll(performances);
  }

  Widget _buildSearchWidget() {
    return CommonAutoSizeTextFormField(
      controller: _searchTextController,
      keyboardType: TextInputType.text,
      suffixIcon: IconButton(
        onPressed: () {
          _refresh(_searchTextController.text);
        },
        icon: Icon(
          Icons.search,
          color: myself.primary,
        ),
      ),
    );
  }

  Widget _buildPerformanceListView(BuildContext context) {
    return BindingDataTable2<Performance>(
      key: UniqueKey(),
      showCheckboxColumn: true,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: performanceDataColumns,
      controller: performanceController,
      fixedLeftColumns: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [];
    return AppBarView(
      title: widget.title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: Column(
        children: [
          _buildSearchWidget(),
          Expanded(child: _buildPerformanceListView(context))
        ],
      ),
    );
  }

  @override
  void dispose() {
    performanceController.removeListener(_updatePerformance);
    super.dispose();
  }
}
