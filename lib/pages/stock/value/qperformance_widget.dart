import 'package:colla_chat/entity/stock/qperformance.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/stock_line_chart_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/qperformance.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_paginated_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

class QPerformanceDataPageController extends DataPageController<QPerformance> {
  @override
  sort<S>(Comparable<S>? Function(QPerformance t) getFieldValue,
      int columnIndex, String columnName, bool ascending) {
    sortColumnIndex = columnIndex;
    sortColumnName = columnName;
    sortAscending = ascending;
    notifyListeners();
  }
}

/// 自选股当前日线的控制器
final QPerformanceDataPageController qperformanceDataPageController =
    QPerformanceDataPageController();

///自选股和分组的查询界面
class QPerformanceWidget extends StatefulWidget with TileDataMixin {
  QPerformanceWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QPerformanceWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'qperformance';

  @override
  IconData get iconData => Icons.area_chart;

  @override
  String get title => 'QPerformance';
}

class _QPerformanceWidgetState extends State<QPerformanceWidget>
    with TickerProviderStateMixin {
  late final List<PlatformDataColumn> qperformanceDataColumns = [
    PlatformDataColumn(
      label: '股票代码',
      name: 'ts_code',
      width: 80,
    ),
    PlatformDataColumn(
      label: '股票名',
      name: 'security_name',
      width: 80,
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
      label: 'pe',
      name: 'pe',
      width: 50,
      dataType: DataType.double,
      align: TextAlign.end,
      onSort: (int index, bool ascending) => qperformanceDataPageController
          .sort((t) => t.pe, index, 'pe', ascending),
    ),
    PlatformDataColumn(
      label: 'peg',
      name: 'peg',
      width: 70,
      dataType: DataType.double,
      align: TextAlign.end,
      onSort: (int index, bool ascending) => qperformanceDataPageController
          .sort((t) => t.peg, index, 'peg', ascending),
    ),
    PlatformDataColumn(
      label: '收盘价',
      name: 'close',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.end,
      width: 80,
      onSort: (int index, bool ascending) => qperformanceDataPageController
          .sort((t) => t.close, index, 'close', ascending),
    ),
    PlatformDataColumn(
      label: '涨幅',
      name: 'pct_chg_close',
      dataType: DataType.percentage,
      align: TextAlign.end,
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
      align: TextAlign.end,
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
      align: TextAlign.end,
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
      align: TextAlign.end,
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
      align: TextAlign.end,
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
      align: TextAlign.end,
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
      align: TextAlign.end,
      width: 80,
      onSort: (int index, bool ascending) =>
          qperformanceDataPageController.sort((t) => t.grossProfitMargin, index,
              'grossProfitMargin', ascending),
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
  int offset = qperformanceDataPageController.offset;
  String? sortColumnName = qperformanceDataPageController.sortColumnName;
  bool sortAscending = qperformanceDataPageController.sortAscending;

  @override
  initState() {
    searchDataField = [
      PlatformDataField(
        name: 'securityCode',
        label: 'SecurityCode',
        cancel: true,
        prefixIcon: IconButton(
          onPressed: () {
            searchController.setValue(
                'securityCode', shareService.subscription);
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
    qperformanceDataPageController.addListener(_updateQPerformance);
    super.initState();
  }

  _updateQPerformance() {
    if (offset != qperformanceDataPageController.offset ||
        sortColumnName != qperformanceDataPageController.sortColumnName ||
        sortAscending != qperformanceDataPageController.sortAscending) {
      offset = qperformanceDataPageController.offset;
      sortColumnName = qperformanceDataPageController.sortColumnName;
      sortAscending = qperformanceDataPageController.sortAscending;
      String? orderBy;
      if (sortColumnName != null) {
        orderBy = '$sortColumnName ${sortAscending ? 'asc' : 'desc'}';
      }
      Map<String, dynamic> values = searchController.getValues();
      String? securityCode = values['securityCode'];
      String? startDate = values['startDate'];
      _refresh(
          securityCode: securityCode, startDate: startDate, orderBy: orderBy);
    } else {
      setState(() {});
    }
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

  _refresh({String? securityCode, String? startDate, String? orderBy}) async {
    int offset = qperformanceDataPageController.offset;
    int limit = qperformanceDataPageController.limit;
    int count = qperformanceDataPageController.count;
    Map<String, dynamic> responseData =
        await remoteQPerformanceService.sendFindByQDate(
            securityCode: securityCode,
            startDate: startDate,
            from: offset,
            limit: limit,
            orderBy: orderBy,
            count: count);
    count = responseData['count'];
    List<QPerformance> qperformances = responseData['data'];
    qperformanceDataPageController.count = count;
    qperformanceDataPageController.replaceAll(qperformances);
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
    qperformanceDataPageController.reset();

    String? securityCode = values['securityCode'];
    String? startDate = values['startDate'];
    _refresh(
      securityCode: securityCode,
      startDate: startDate,
    );
    expansionTileController.collapse();
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('QPerformance search completely'));
    }
  }

  Widget _buildQPerformanceListView(BuildContext context) {
    return BindingPaginatedDataTable2<QPerformance>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: qperformanceDataColumns,
      controller: qperformanceDataPageController,
      fixedLeftColumns: 3,
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
          _buildSearchView(context),
          Expanded(child: _buildQPerformanceListView(context))
        ],
      ),
    );
  }

  @override
  void dispose() {
    qperformanceDataPageController.removeListener(_updateQPerformance);
    super.dispose();
  }
}
