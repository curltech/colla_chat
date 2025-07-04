import 'dart:async';

import 'package:colla_chat/entity/stock/stat_score.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/my_selection_widget.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/stat_score.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/form_input_widget.dart';
import 'package:flutter/material.dart';

class StatScoreDataPageController extends DataPageController<StatScore> {
  @override
  sort<S>(Comparable<S>? Function(StatScore t) getFieldValue, int columnIndex,
      String columnName, bool ascending) {
    findCondition.value = findCondition.value
        .copy(sortColumns: [SortColumn(columnIndex, columnName, ascending)]);
  }

  @override
  FutureOr<void> findData() async {
    Map<String, dynamic> responseData = await remoteStatScoreService.sendSearch(
        tsCode: findCondition.value.whereColumns['tsCode'],
        terms: findCondition.value.whereColumns['terms'],
        from: findCondition.value.offset,
        // limit: findCondition.value.limit,
        orderBy: orderBy(),
        count: findCondition.value.count);
    findCondition.value.count = responseData['count'];
    List<StatScore> statScores = responseData['data'];
    replaceAll(statScores);
  }
}

/// 统计指标
final StatScoreDataPageController statScoreDataPageController =
    StatScoreDataPageController();

///自选股和分组的查询界面
class StatScoreWidget extends StatelessWidget with TileDataMixin {
  StatScoreWidget({super.key}) {
    _init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'stat_score';

  @override
  IconData get iconData => Icons.score_outlined;

  @override
  String get title => 'StatScore';

  

  late final List<PlatformDataField> searchDataField;
  late final FormInputController searchController;
  final ExpansibleController expansibleController =
      ExpansibleController();

  _init() {
    statScoreDataPageController.findCondition.addListener(_updateStatScore);
    searchDataField = [
      PlatformDataField(
        name: 'keyword',
        label: 'Keyword',
        cancel: true,
        prefixIcon: Icon(
          Icons.wordpress_outlined,
          color: myself.primary,
        ),
      ),
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
    ];
    searchController = FormInputController(searchDataField);
  }

  _updateStatScore() {
    Map<String, dynamic> values = searchController.getValues();
    statScoreDataPageController.findCondition.value.whereColumns = values;
    statScoreDataPageController.findData();
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
            _onOk(values);
          }),
    ];
    Widget formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: appDataProvider.portraitSize.height * 0.3,
          spacing: 5.0,
          controller: searchController,
          formButtons: formButtonDefs,
        ));

    formInputWidget = ExpansionTile(
      title: Text(AppLocalizations.t('Search')),
      initiallyExpanded: true,
      controller: expansibleController,
      children: [formInputWidget],
    );

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) async {
    String? tsCode = values['tsCode'];
    statScoreDataPageController.findCondition.value.whereColumns = {
      'tsCode': tsCode,
      'terms': values['terms']?.toList(),
    };
    await statScoreDataPageController.findData();
    expansibleController.collapse();
    DialogUtil.info(content: AppLocalizations.t('StatScore search completely'));
  }

  Widget _buildStatScoreListView(BuildContext context) {
    final List<PlatformDataColumn> statScoreDataColumns = [
      PlatformDataColumn(
        label: '股票名',
        name: 'security_name',
        width: 80,
      ),
      PlatformDataColumn(
        label: '风险',
        name: 'risk_score',
        width: 50,
        dataType: DataType.double,
        align: Alignment.centerRight,
        onSort: (int index, bool ascending) => statScoreDataPageController.sort(
            (t) => t.riskScore, index, 'riskScore', ascending),
      ),
      PlatformDataColumn(
        label: '稳定',
        name: 'stable_score',
        width: 70,
        dataType: DataType.double,
        align: Alignment.centerRight,
        onSort: (int index, bool ascending) => statScoreDataPageController.sort(
            (t) => t.stableScore, index, 'stableScore', ascending),
      ),
      PlatformDataColumn(
        label: '增长',
        name: 'increase_score',
        dataType: DataType.double,
        align:Alignment.centerRight,
        width: 80,
        onSort: (int index, bool ascending) => statScoreDataPageController.sort(
            (t) => t.increaseScore, index, 'increaseScore', ascending),
      ),
      PlatformDataColumn(
        label: '累计业绩',
        name: 'acc_score',
        dataType: DataType.double,
        align:Alignment.centerRight,
        width: 80,
        onSort: (int index, bool ascending) => statScoreDataPageController.sort(
            (t) => t.accScore, index, 'accScore', ascending),
      ),
      PlatformDataColumn(
        label: '相关性',
        name: 'corr_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 100,
        onSort: (int index, bool ascending) => statScoreDataPageController.sort(
            (t) => t.corrScore, index, 'corrScore', ascending),
      ),
      PlatformDataColumn(
        label: '最新业绩',
        name: 'pros_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 110,
        onSort: (int index, bool ascending) => statScoreDataPageController.sort(
            (t) => t.prosScore, index, 'prosScore', ascending),
      ),
      PlatformDataColumn(
        label: '趋势',
        name: 'trend_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 110,
        onSort: (int index, bool ascending) => statScoreDataPageController.sort(
            (t) => t.trendScore, index, 'trendScore', ascending),
      ),
      PlatformDataColumn(
        label: '运营',
        name: 'operation_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 130,
        onSort: (int index, bool ascending) => statScoreDataPageController.sort(
            (t) => t.operationScore, index, 'operationScore', ascending),
      ),
      PlatformDataColumn(
        label: '总分',
        name: 'total_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 100,
        onSort: (int index, bool ascending) => statScoreDataPageController.sort(
            (t) => t.totalScore, index, 'totalScore', ascending),
      ),
      PlatformDataColumn(
        label: '总分分位数',
        name: 'percentile_total_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 100,
        onSort: (int index, bool ascending) => statScoreDataPageController.sort(
            (t) => t.percentileTotalScore,
            index,
            'percentileTotalScore',
            ascending),
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
    return BindingTrinaDataGrid<StatScore>(
      key: UniqueKey(),
      minWidth: 1400,
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: statScoreDataColumns,
      controller: statScoreDataPageController,
      fixedLeftColumns: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [];
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: Column(
        children: [
          _buildSearchView(context),
          Expanded(child: _buildStatScoreListView(context))
        ],
      ),
    );
  }
}
