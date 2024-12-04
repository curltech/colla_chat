import 'package:colla_chat/entity/stock/performance.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/performance.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_paginated_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PerformanceDataPageController extends DataPageController<Performance> {
  @override
  sort<S>(Comparable<S>? Function(Performance t) getFieldValue, int columnIndex,
      String columnName, bool ascending) {
    sortColumnIndex(columnIndex);
    sortColumnName(columnName);
    sortAscending(ascending);
  }
}

/// 自选股当前日线的控制器
final PerformanceDataPageController performanceDataPageController =
    PerformanceDataPageController();

///自选股和分组的查询界面
class PerformanceWidget extends StatelessWidget with TileDataMixin {
  PerformanceWidget({super.key}) {
    _init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'performance';

  @override
  IconData get iconData => Icons.bar_chart;

  @override
  String get title => 'Performance';

  late final List<PlatformDataColumn> performanceDataColumns = [
    PlatformDataColumn(
      label: '股票名',
      name: 'security_name_abbr',
      width: 80,
    ),
    PlatformDataColumn(
      label: '业绩日期',
      name: 'qdate',
      width: 60,
    ),
    PlatformDataColumn(
      label: '年营收增长',
      name: 'yoy_sales',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.right,
      width: 100,
      onSort: (int index, bool ascending) => performanceDataPageController.sort(
          (t) => t.yoySales, index, 'yoySales', ascending),
    ),
    PlatformDataColumn(
      label: '年净利润增长',
      name: 'yoy_dedu_np',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.right,
      width: 110,
      onSort: (int index, bool ascending) => performanceDataPageController.sort(
          (t) => t.yoyDeduNp, index, 'yoyDeduNp', ascending),
    ),
    PlatformDataColumn(
      label: '环比营收增长',
      name: 'or_last_month',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.right,
      width: 110,
      onSort: (int index, bool ascending) => performanceDataPageController.sort(
          (t) => t.orLastMonth, index, 'orLastMonth', ascending),
    ),
    PlatformDataColumn(
      label: '环比净利润增长',
      name: 'np_last_month',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.right,
      width: 130,
      onSort: (int index, bool ascending) => performanceDataPageController.sort(
          (t) => t.npLastMonth, index, 'npLastMonth', ascending),
    ),
    PlatformDataColumn(
      label: '净资产收益率',
      name: 'weight_avg_roe',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.right,
      width: 100,
      onSort: (int index, bool ascending) => performanceDataPageController.sort(
          (t) => t.weightAvgRoe, index, 'weightAvgRoe', ascending),
    ),
    PlatformDataColumn(
      label: '毛利率',
      name: 'gross_profit_margin',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.right,
      width: 80,
      onSort: (int index, bool ascending) => performanceDataPageController.sort(
          (t) => t.grossProfitMargin, index, 'grossProfitMargin', ascending),
    ),
    PlatformDataColumn(
      label: '基本每股收益',
      name: 'basic_eps',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.right,
      width: 110,
      onSort: (int index, bool ascending) => performanceDataPageController.sort(
          (t) => t.basicEps, index, 'basicEps', ascending),
    ),
    PlatformDataColumn(
      label: '总营收',
      name: 'total_operate_income',
      dataType: DataType.double,
      align: TextAlign.right,
      width: 140,
      onSort: (int index, bool ascending) => performanceDataPageController.sort(
          (t) => t.totalOperateIncome, index, 'totalOperateIncome', ascending),
    ),
    PlatformDataColumn(
      label: '归母净利润',
      name: 'parent_net_profit',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.right,
      width: 140,
      onSort: (int index, bool ascending) => performanceDataPageController.sort(
          (t) => t.parentNetProfit, index, 'parentNetProfit', ascending),
    ),
    PlatformDataColumn(
        label: '',
        name: 'action',
        inputType: InputType.custom,
        width: 20,
        buildSuffix: (int index, dynamic data) {
          return nil;
        }),
    PlatformDataColumn(
      label: '股票代码',
      name: 'security_code',
      align: TextAlign.right,
      width: 120,
    ),
    PlatformDataColumn(
      label: '业绩类型',
      name: 'data_type',
      width: 100,
    ),
    PlatformDataColumn(
        label: '',
        name: 'action',
        inputType: InputType.custom,
        buildSuffix: _buildActionWidget),
  ];
  late final List<PlatformDataField> searchDataField;
  late final FormInputController searchController;
  ExpansionTileController expansionTileController = ExpansionTileController();

  _init() {
    performanceDataPageController.offset.addListener(_updatePerformance);
    performanceDataPageController.sortColumnName
        .addListener(_updatePerformance);
    performanceDataPageController.sortAscending.addListener(_updatePerformance);
    searchDataField = [
      PlatformDataField(
        name: 'securityCode',
        label: 'SecurityCode',
        cancel: true,
        prefixIcon: IconButton(
          onPressed: () {
            searchController.setValue(
                'securityCode', myShareController.subscription.value);
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
    searchController = FormInputController(searchDataField);
    searchController.setValue(
        'startDate', DateUtil.formatDateQuarter(DateTime.now()));
  }

  _updatePerformance() {
    var offset = performanceDataPageController.offset;
    var sortColumnName = performanceDataPageController.sortColumnName;
    var sortAscending = performanceDataPageController.sortAscending;
    String? orderBy;
    if (sortColumnName.value != null) {
      orderBy = '$sortColumnName ${sortAscending.value ? 'asc' : 'desc'}';
    }
    Map<String, dynamic> values = searchController.getValues();
    String? securityCode = values['securityCode'];
    String? startDate = values['startDate'];
    _refresh(
        securityCode: securityCode, startDate: startDate, orderBy: orderBy);
  }

  Widget _buildActionWidget(int index, dynamic performance) {
    Widget actionWidget = Row(
      children: [
        const SizedBox(
          width: 10,
        ),
        IconButton(
          onPressed: () async {
            String tsCode = performance.securityCode;
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

  _refresh({String? securityCode, String? startDate, String? orderBy}) async {
    RxInt offset = performanceDataPageController.offset;
    RxInt limit = performanceDataPageController.limit;
    RxInt count = performanceDataPageController.count;
    Map<String, dynamic> responseData =
        await remotePerformanceService.sendFindByQDate(
            securityCode: securityCode,
            startDate: startDate,
            from: offset.value,
            limit: limit.value,
            orderBy: orderBy,
            count: count.value);
    count(responseData['count']);
    List<Performance> performances = responseData['data'];
    performanceDataPageController.count(count.value);
    performanceDataPageController.replaceAll(performances);
  }

  /// 构建搜索条件
  Widget _buildSearchView(BuildContext context) {
    List<FormButton> formButtonDefs = [
      FormButton(
          label: 'Ok',
          onTap: (Map<String, dynamic> values) {
            _onOk(values);
          }),
    ];
    Widget formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: appDataProvider.portraitSize.height * 0.2,
          spacing: 5.0,
          controller: searchController,
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

  _onOk(Map<String, dynamic> values) async {
    performanceDataPageController.reset();

    String? securityCode = values['securityCode'];
    String? startDate = values['startDate'];
    _refresh(
      securityCode: securityCode,
      startDate: startDate,
    );
    expansionTileController.collapse();
  }

  Widget _buildPerformanceListView(BuildContext context) {
    return BindingPaginatedDataTable2<Performance>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: performanceDataColumns,
      controller: performanceDataPageController,
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
          Expanded(child: _buildPerformanceListView(context))
        ],
      ),
    );
  }
}
