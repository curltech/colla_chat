import 'dart:async';

import 'package:colla_chat/entity/stock/qperformance.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/qperformance.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_paginated_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';

class QPerformanceDataPageController extends DataPageController<QPerformance> {
  @override
  sort<S>(Comparable<S>? Function(QPerformance t) getFieldValue,
      int columnIndex, String columnName, bool ascending) {
    findCondition.value = findCondition.value
        .copy(sortColumns: [SortColumn(columnIndex, columnName, ascending)]);
  }

  @override
  FutureOr<void> findData() async {
    Map<String, dynamic> responseData =
        await remoteQPerformanceService.sendFindByQDate(
            tsCode: findCondition.value.whereColumns['tsCode'],
            startDate: findCondition.value.whereColumns['startDate'],
            from: findCondition.value.offset,
            limit: findCondition.value.limit,
            orderBy: orderBy(),
            count: findCondition.value.count);
    findCondition.value.count = responseData['count'];
    List<QPerformance> qperformances = responseData['data'];
    replaceAll(qperformances);
  }
}

/// 自选股当前日线的控制器
final QPerformanceDataPageController qperformanceDataPageController =
    QPerformanceDataPageController();

///自选股和分组的查询界面
class QPerformanceWidget extends StatelessWidget with TileDataMixin {
  QPerformanceWidget({super.key}) {
    _init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'qperformance';

  @override
  IconData get iconData => Icons.area_chart;

  @override
  String get title => 'QPerformance';

  late final List<PlatformDataField> searchDataField;
  late final PlatformReactiveFormController searchController;
  final ExpansionTileController expansionTileController =
      ExpansionTileController();

  _init() {
    qperformanceDataPageController.findCondition
        .addListener(_updateQPerformance);
    searchDataField = [
      PlatformDataField(
        name: 'tsCode',
        label: 'TsCode',
        cancel: true,
        prefixIcon: IconButton(
          onPressed: () {
            searchController.setValue(
                'tsCode', myShareController.subscription.value);
          },
          icon: Icon(
            Icons.perm_identity_outlined,
            color: myself.primary,
          ),
        ),
      ),
      PlatformDataField(
          name: 'startDate',
          label: 'StartDate',
          prefixIcon: Icon(
            Icons.date_range_outlined,
            color: myself.primary,
          )),
    ];
    searchController = PlatformReactiveFormController(searchDataField);
    searchController.setValue(
        'startDate', DateUtil.formatDateQuarter(DateTime.now()));
  }

  _updateQPerformance() {
    Map<String, dynamic> values = searchController.values;
    qperformanceDataPageController.findCondition.value.whereColumns = values;
    qperformanceDataPageController.findData();
  }

  Widget _buildActionWidget(int index, dynamic qperformance) {
    Widget actionWidget = Row(
      children: [
        const SizedBox(
          width: 10,
        ),
        IconButton(
          onPressed: () async {
            String tsCode = qperformance.securityCode;
            await multiKlineController.put(tsCode);
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

  /// 构建搜索条件
  Widget _buildSearchView(BuildContext context) {
    List<FormButton> formButtonDefs = [
      FormButton(
          label: 'Ok',
          onTap: (Map<String, dynamic> values) {
            _onOk(context, values);
          }),
    ];
    Widget formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: PlatformReactiveForm(
          height: appDataProvider.portraitSize.height * 0.2,
          spacing: 5.0,
          platformReactiveFormController: searchController,
          formButtons: formButtonDefs,
        ));

    formInputWidget = ExpansionTile(
      title: Text(AppLocalizations.t('Search')),
      initiallyExpanded: true,
      controller: expansionTileController,
      children: [formInputWidget],
    );

    return formInputWidget;
  }

  _onOk(BuildContext context, Map<String, dynamic> values) async {
    qperformanceDataPageController.findCondition.value.whereColumns = values;
    await qperformanceDataPageController.findData();
    expansionTileController.collapse();
    DialogUtil.info(
        content: AppLocalizations.t('QPerformance search completely'));
  }

  Widget _buildQPerformanceListView(BuildContext context) {
    final List<PlatformDataColumn> qperformanceDataColumns = [
      PlatformDataColumn(
        label: '股票名',
        name: 'security_name',
        width: 80,
      ),
      PlatformDataColumn(
        label: 'pe',
        name: 'pe',
        width: 50,
        dataType: DataType.double,
        align: Alignment.centerRight,
        onSort: (int index, bool ascending) => qperformanceDataPageController
            .sort((t) => t.pe, index, 'pe', ascending),
      ),
      PlatformDataColumn(
        label: 'peg',
        name: 'peg',
        width: 70,
        dataType: DataType.double,
        align: Alignment.centerRight,
        onSort: (int index, bool ascending) => qperformanceDataPageController
            .sort((t) => t.peg, index, 'peg', ascending),
      ),
      PlatformDataColumn(
        label: '收盘价',
        name: 'close',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 80,
        onSort: (int index, bool ascending) => qperformanceDataPageController
            .sort((t) => t.close, index, 'close', ascending),
      ),
      PlatformDataColumn(
        label: '涨幅',
        name: 'pct_chg_close',
        dataType: DataType.percentage,
        align: Alignment.centerRight,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        width: 80,
        onSort: (int index, bool ascending) => qperformanceDataPageController
            .sort((t) => t.pctChgClose, index, 'pctChgClose', ascending),
      ),
      PlatformDataColumn(
        label: '年营收增长',
        name: 'yoy_sales',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 100,
        onSort: (int index, bool ascending) => qperformanceDataPageController
            .sort((t) => t.yoySales, index, 'yoySales', ascending),
      ),
      PlatformDataColumn(
        label: '年净利润增长',
        name: 'yoy_dedu_np',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 110,
        onSort: (int index, bool ascending) => qperformanceDataPageController
            .sort((t) => t.yoyDeduNp, index, 'yoyDeduNp', ascending),
      ),
      PlatformDataColumn(
        label: '环比营收增长',
        name: 'or_last_month',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 110,
        onSort: (int index, bool ascending) => qperformanceDataPageController
            .sort((t) => t.orLastMonth, index, 'orLastMonth', ascending),
      ),
      PlatformDataColumn(
        label: '环比净利润增长',
        name: 'np_last_month',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 130,
        onSort: (int index, bool ascending) => qperformanceDataPageController
            .sort((t) => t.npLastMonth, index, 'npLastMonth', ascending),
      ),
      PlatformDataColumn(
        label: '净资产收益率',
        name: 'weight_avg_roe',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 100,
        onSort: (int index, bool ascending) => qperformanceDataPageController
            .sort((t) => t.weightAvgRoe, index, 'weightAvgRoe', ascending),
      ),
      PlatformDataColumn(
        label: '毛利率',
        name: 'gross_profit_margin',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 80,
        onSort: (int index, bool ascending) =>
            qperformanceDataPageController.sort((t) => t.grossProfitMargin,
                index, 'grossProfitMargin', ascending),
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          inputType: InputType.custom,
          width: 20,
          buildSuffix: (int index, dynamic data) {
            return nilBox;
          }),
      PlatformDataColumn(
        label: '股票代码',
        name: 'ts_code',
        width: 100,
      ),
      PlatformDataColumn(
        label: '业绩日期',
        name: 'qdate',
        width: 90,
      ),
      PlatformDataColumn(
        label: '交易日期',
        name: 'trade_date',
        width: 80,
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          inputType: InputType.custom,
          buildSuffix: (int index, dynamic qperformance) {
            return _buildActionWidget(index, qperformance);
          }),
    ];

    return BindingPaginatedDataTable2<QPerformance>(
      key: UniqueKey(),
      minWidth: 1400,
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: qperformanceDataColumns,
      controller: qperformanceDataPageController,
      fixedLeftColumns: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [];
    return AppBarView(
      title: title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: Column(
        children: [
          _buildSearchView(context),
          Expanded(child: _buildQPerformanceListView(context))
        ],
      ),
    );
  }
}
