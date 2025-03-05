import 'dart:async';

import 'package:colla_chat/entity/stock/qstat.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/qstat.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

class QStatDataPageController extends DataPageController<QStat> {
  @override
  sort<S>(Comparable<S>? Function(QStat t) getFieldValue, int columnIndex,
      String columnName, bool ascending) {
    findCondition.value = findCondition.value
        .copy(sortColumns: [SortColumn(columnIndex, columnName, ascending)]);
  }

  @override
  FutureOr<void> findData() async {
    Map<String, dynamic> responseData =
        await remoteQStatService.sendFindQStatBy(
            tsCode: findCondition.value.whereColumns['tsCode'],
            terms: findCondition.value.whereColumns['terms'],
            source: findCondition.value.whereColumns['source'],
            from: findCondition.value.offset,
            // limit: findCondition.value.limit,
            orderBy: orderBy(),
            count: findCondition.value.count);
    findCondition.value.count = responseData['count'];
    List<QStat> qstats = responseData['data'];
    replaceAll(qstats);
  }
}

/// 统计指标
final QStatDataPageController qstatDataPageController =
    QStatDataPageController();

///自选股和分组的查询界面
class QStatWidget extends StatelessWidget with TileDataMixin {
  QStatWidget({super.key}) {
    _init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'qstat';

  @override
  IconData get iconData => Icons.ssid_chart;

  @override
  String get title => 'QStat';

  

  late final List<PlatformDataField> searchDataField;
  late final FormInputController searchController;
  final ExpansionTileController expansionTileController =
      ExpansionTileController();

  _init() {
    qstatDataPageController.findCondition.addListener(_updateQStat);
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
  }

  _updateQStat() {
    Map<String, dynamic> values = searchController.getValues();
    qstatDataPageController.findCondition.value.whereColumns = values;
    qstatDataPageController.findData();
  }

  Widget _buildActionWidget(int index, dynamic qstat) {
    Widget actionWidget = Row(
      children: [
        const SizedBox(
          width: 10,
        ),
        Expanded(
            child: IconButton(
          onPressed: () async {
            String tsCode = qstat.tsCode;
            await multiKlineController.put(tsCode);
            indexWidgetProvider.push('stockline_chart');
          },
          icon: const Icon(
            Icons.filter,
            color: Colors.yellow,
          ),
          tooltip: AppLocalizations.t('StockLineChart'),
        ))
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
        child: FormInputWidget(
          height: appDataProvider.portraitSize.height * 0.35,
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

  _onOk(BuildContext context, Map<String, dynamic> values) async {
    String? tsCode = values['tsCode'];
    if (tsCode == null) {
      DialogUtil.error(content: 'tsCode must be value');
      return;
    }
    qstatDataPageController.findCondition.value.whereColumns = {
      'tsCode': tsCode,
      'terms': values['terms']?.toList(),
      'source': values['source']?.toList(),
    };
    await qstatDataPageController.findData();
    expansionTileController.collapse();
    DialogUtil.info(content: AppLocalizations.t('QStat search completely'));
  }

  Widget _buildQStatListView(BuildContext context) {
    final List<PlatformDataColumn> qstatDataColumns = [
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
            return nil;
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

    return BindingDataTable2<QStat>(
      key: UniqueKey(),
      minWidth: 1400,
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
      title: title,
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
}
