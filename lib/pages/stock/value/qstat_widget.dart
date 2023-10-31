import 'package:colla_chat/entity/stock/qperformance.dart';
import 'package:colla_chat/entity/stock/qstat.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/stock_line_chart_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/qperformance.dart';
import 'package:colla_chat/service/stock/qstat.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/binging_paginated_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

class QStatDataPageController extends DataPageController<QStat> {
  @override
  sort<S>(Comparable<S>? Function(QStat t) getFieldValue, int columnIndex,
      String columnName, bool ascending) {
    sortColumnIndex = columnIndex;
    sortColumnName = columnName;
    sortAscending = ascending;
    notifyListeners();
  }
}

/// 统计指标
final QStatDataPageController qstatDataPageController =
    QStatDataPageController();

///自选股和分组的查询界面
class QStatWidget extends StatefulWidget with TileDataMixin {
  QStatWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QStatWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'qstat';

  @override
  IconData get iconData => Icons.ssid_chart;

  @override
  String get title => 'QStat';
}

class _QStatWidgetState extends State<QStatWidget>
    with TickerProviderStateMixin {
  late final List<PlatformDataColumn> qstatDataColumns = [
    PlatformDataColumn(
      label: '股票名',
      name: 'security_name',
      width: 80,
    ),
    PlatformDataColumn(
      label: '指标',
      name: 'source',
      width: 80,
    ),
    PlatformDataColumn(
      label: 'pe',
      name: 'pe',
      width: 50,
      dataType: DataType.double,
      align: TextAlign.right,
      onSort: (int index, bool ascending) =>
          qstatDataPageController.sort((t) => t.pe, index, 'pe', ascending),
    ),
    PlatformDataColumn(
      label: 'peg',
      name: 'peg',
      width: 70,
      dataType: DataType.double,
      align: TextAlign.right,
      onSort: (int index, bool ascending) =>
          qstatDataPageController.sort((t) => t.peg, index, 'peg', ascending),
    ),
    PlatformDataColumn(
      label: '收盘价',
      name: 'close',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.right,
      width: 80,
      onSort: (int index, bool ascending) => qstatDataPageController.sort(
          (t) => t.close, index, 'close', ascending),
    ),
    PlatformDataColumn(
      label: '涨幅',
      name: 'pct_chg_close',
      dataType: DataType.percentage,
      align: TextAlign.right,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      width: 80,
      onSort: (int index, bool ascending) => qstatDataPageController.sort(
          (t) => t.pctChgClose, index, 'pctChgClose', ascending),
    ),
    PlatformDataColumn(
      label: '年营收增长',
      name: 'yoy_sales',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: TextAlign.right,
      width: 100,
      onSort: (int index, bool ascending) => qstatDataPageController.sort(
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
      onSort: (int index, bool ascending) => qstatDataPageController.sort(
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
      onSort: (int index, bool ascending) => qstatDataPageController.sort(
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
      onSort: (int index, bool ascending) => qstatDataPageController.sort(
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
      onSort: (int index, bool ascending) => qstatDataPageController.sort(
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
      onSort: (int index, bool ascending) => qstatDataPageController.sort(
          (t) => t.grossProfitMargin, index, 'grossProfitMargin', ascending),
    ),
    PlatformDataColumn(
        label: '',
        name: 'action',
        inputType: InputType.custom,
        width: 20,
        buildSuffix: (int index, dynamic data) {
          return Container();
        }),
    PlatformDataColumn(
      label: '股票代码',
      name: 'ts_code',
      width: 100,
    ),
    PlatformDataColumn(
      label: '年份',
      name: 'term',
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
        buildSuffix: _buildActionWidget),
  ];
  late final List<PlatformDataField> searchDataField;
  late final FormInputController searchController;
  ExpansionTileController expansionTileController = ExpansionTileController();
  int offset = qstatDataPageController.offset;
  String? sortColumnName = qstatDataPageController.sortColumnName;
  bool sortAscending = qstatDataPageController.sortAscending;

  @override
  initState() {
    searchDataField = [
      PlatformDataField(
        name: 'tsCode',
        label: 'TsCode',
        cancel: true,
        prefixIcon: IconButton(
          onPressed: () {
            searchController.setValue('tsCode', shareService.subscription);
          },
          icon: Icon(
            Icons.perm_identity_outlined,
            color: myself.primary,
          ),
        ),
      ),
      PlatformDataField(
          name: 'terms',
          label: 'Terms',
          inputType: InputType.checkbox,
          dataType: DataType.set,
          options: [
            Option('全部', 0),
            Option('1年', 1),
            Option('3年', 3),
            Option('5年', 5),
            Option('8年', 8),
            Option('10年', 10),
            Option('15年', 15)
          ],
          prefixIcon: Icon(
            Icons.date_range_outlined,
            color: myself.primary,
          )),
      PlatformDataField(
          name: 'source',
          label: 'Source',
          inputType: InputType.checkbox,
          dataType: DataType.set,
          options: [
            Option('最小', 'min'),
            Option('最大', 'max'),
            Option('合计', 'sum'),
            Option('均值', 'mean'),
            Option('中位数', 'median'),
            Option('标准差', 'stddev'),
            Option('相关性', 'corr'),
            Option('最新', 'last'),
            Option('相对相关性', 'rsd'),
            Option('累计', 'acc')
          ],
          prefixIcon: Icon(
            Icons.indeterminate_check_box_outlined,
            color: myself.primary,
          )),
    ];
    searchController = FormInputController(searchDataField);
    searchController.setValue(
        'startDate', DateUtil.formatDateQuarter(DateTime.now()));
    qstatDataPageController.addListener(_updateQStat);
    super.initState();
  }

  _updateQStat() {
    if (offset != qstatDataPageController.offset ||
        sortColumnName != qstatDataPageController.sortColumnName ||
        sortAscending != qstatDataPageController.sortAscending) {
      offset = qstatDataPageController.offset;
      sortColumnName = qstatDataPageController.sortColumnName;
      sortAscending = qstatDataPageController.sortAscending;
      String? orderBy;
      if (sortColumnName != null) {
        orderBy = '$sortColumnName ${sortAscending ? 'asc' : 'desc'}';
      }
      Map<String, dynamic> values = searchController.getValues();
      String? tsCode = values['tsCode'];
      Set<dynamic>? terms = values['terms'];
      Set<dynamic>? source = values['source'];
      _refresh(
          tsCode: tsCode,
          terms: terms?.toList(),
          source: source?.toList(),
          orderBy: orderBy);
    } else {
      setState(() {});
    }
  }

  Widget _buildActionWidget(int index, dynamic qstat) {
    Widget actionWidget = Row(
      children: [
        const SizedBox(
          width: 10,
        ),
        IconButton(
          onPressed: () async {
            String tsCode = qstat.tsCode;
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

  _refresh(
      {String? tsCode,
      List<dynamic>? terms,
      List<dynamic>? source,
      String? orderBy}) async {
    int offset = qstatDataPageController.offset;
    int count = qstatDataPageController.count;
    Map<String, dynamic> responseData =
        await remoteQStatService.sendFindQStatBy(
            tsCode: tsCode,
            terms: terms,
            source: source,
            from: offset,
            orderBy: orderBy,
            count: count);
    count = responseData['count'];
    List<QStat> qstats = responseData['data'];
    qstatDataPageController.count = count;
    qstatDataPageController.replaceAll(qstats);
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
          height: appDataProvider.portraitSize.height * 0.4,
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
    qstatDataPageController.reset();
    String? tsCode = values['tsCode'];
    if (tsCode == null) {
      DialogUtil.error(context, content: 'tsCode must be value');
      return;
    }
    Set<dynamic>? terms = values['terms'];
    Set<dynamic>? source = values['source'];
    _refresh(
      tsCode: tsCode,
      terms: terms?.toList(),
      source: source?.toList(),
    );
    expansionTileController.collapse();
  }

  Widget _buildQStatListView(BuildContext context) {
    return BindingDataTable2<QStat>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: qstatDataColumns,
      controller: qstatDataPageController,
      fixedLeftColumns: 1,
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
          Expanded(child: _buildQStatListView(context))
        ],
      ),
    );
  }

  @override
  void dispose() {
    qstatDataPageController.removeListener(_updateQStat);
    super.dispose();
  }
}
