import 'package:colla_chat/entity/stock/stat_score.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/stat_score.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

///自选股和分组的查询界面
class StatScoreWidget extends StatelessWidget with DataTileMixin {
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
  late final PlatformReactiveFormController searchController;
  final ExpansibleController expansibleController = ExpansibleController();
  final DataListController<StatScore> statScoreController =
      DataListController<StatScore>();

  void _init() {
    searchDataField = [
      PlatformDataField(
        name: 'keyword',
        label: 'Keyword',
        cancel: true,
        prefixIcon: Icon(
          Icons.wordpress_outlined,
          color: myself.primary,
        ),
        validators: [Validators.required],
        validationMessages: {
          ValidationMessage.required: (_) => 'The keyword must not be empty',
        },
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
        ),
        validators: [Validators.required],
        validationMessages: {
          ValidationMessage.required: (_) => 'The terms must not be empty',
        },
      ),
    ];
    searchController = PlatformReactiveFormController(searchDataField);
  }

  Future<void> refresh(
    String tsCode, {
    List<dynamic>? terms,
  }) async {
    Map<String, dynamic> responseData =
        await remoteStatScoreService.sendSearch(tsCode: tsCode, terms: terms);
    var count = responseData['count'];
    List<StatScore> statScores = responseData['data'];
    statScoreController.replaceAll(statScores);
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
    Widget platformReactiveForm = Container(
      padding: const EdgeInsets.all(10.0),
      child: PlatformReactiveForm(
          height: appDataProvider.portraitSize.height * 0.4,
          spacing: 5.0,
          platformReactiveFormController: searchController,
          onSubmit: (Map<String, dynamic> values) {
            _onSubmit(values);
          }),
    );

    platformReactiveForm = ExpansionTile(
      title: Text(AppLocalizations.t('Search')),
      initiallyExpanded: true,
      controller: expansibleController,
      children: [platformReactiveForm],
    );

    return platformReactiveForm;
  }

  Future<void> _onSubmit(Map<String, dynamic> values) async {
    String? tsCode = values['tsCode'];
    if (tsCode == null) {
      DialogUtil.error(content: 'tsCode must be value');
      return;
    }
    statScoreController.findCondition.value.whereColumns = {
      'tsCode': tsCode,
      'terms': values['terms']?.toList(),
    };
    await refresh(tsCode, terms: values['terms']?.toList());
    expansibleController.collapse();
    DialogUtil.info(content: AppLocalizations.t('StatScore search completely'));
  }

  Widget _buildStatScoreListView(BuildContext context) {
    final List<PlatformDataColumn> statScoreDataColumns = [
      PlatformDataColumn(
        label: AppLocalizations.t('tsCode'),
        name: 'ts_code',
        width: 100,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('term'),
        name: 'term',
        width: 90,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('tradeDate'),
        name: 'trade_date',
        width: 80,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('securityName'),
        name: 'security_name',
        width: 80,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('riskScore'),
        name: 'risk_score',
        width: 50,
        dataType: DataType.double,
        align: Alignment.centerRight,
        onSort: (int index, bool ascending) => statScoreController.sort(
            (t) => t.riskScore, index, 'riskScore', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('stableScore'),
        name: 'stable_score',
        width: 70,
        dataType: DataType.double,
        align: Alignment.centerRight,
        onSort: (int index, bool ascending) => statScoreController.sort(
            (t) => t.stableScore, index, 'stableScore', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('increaseScore'),
        name: 'increase_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 80,
        onSort: (int index, bool ascending) => statScoreController.sort(
            (t) => t.increaseScore, index, 'increaseScore', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('accScore'),
        name: 'acc_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 80,
        onSort: (int index, bool ascending) => statScoreController.sort(
            (t) => t.accScore, index, 'accScore', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('corrScore'),
        name: 'corr_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 100,
        onSort: (int index, bool ascending) => statScoreController.sort(
            (t) => t.corrScore, index, 'corrScore', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('prosScore'),
        name: 'pros_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 110,
        onSort: (int index, bool ascending) => statScoreController.sort(
            (t) => t.prosScore, index, 'prosScore', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('trendScore'),
        name: 'trend_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 110,
        onSort: (int index, bool ascending) => statScoreController.sort(
            (t) => t.trendScore, index, 'trendScore', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('operationScore'),
        name: 'operation_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 130,
        onSort: (int index, bool ascending) => statScoreController.sort(
            (t) => t.operationScore, index, 'operationScore', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('totalScore'),
        name: 'total_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 100,
        onSort: (int index, bool ascending) => statScoreController.sort(
            (t) => t.totalScore, index, 'totalScore', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('percentileTotalScore'),
        name: 'percentile_total_score',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 100,
        onSort: (int index, bool ascending) => statScoreController.sort(
            (t) => t.percentileTotalScore,
            index,
            'percentileTotalScore',
            ascending),
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          inputType: InputType.custom,
          buildSuffix: _buildActionWidget),
    ];
    return BindingTrinaDataGrid<StatScore>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: statScoreDataColumns,
      controller: statScoreController,
      fixedLeftColumns: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [];
    return AppBarView(
      title: title,
      helpPath: routeName,
      isAppBar: false,
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
