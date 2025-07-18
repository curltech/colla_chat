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
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

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
  late final PlatformReactiveFormController searchController;
  final DataListController<QStat> qstatController = DataListController<QStat>();
  final ExpansibleController expansibleController = ExpansibleController();

  _init() {
    searchDataField = [
      PlatformDataField(
        name: 'startDate',
        label: AppLocalizations.t('startDate'),
        prefixIcon: Icon(
          Icons.date_range_outlined,
          color: myself.primary,
        ),
        validators: [Validators.required],
        validationMessages: {
          ValidationMessage.required: (_) => 'The startDate must not be empty',
        },
      ),
      PlatformDataField(
        name: 'tsCode',
        label: AppLocalizations.t('tsCode'),
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
        label: AppLocalizations.t('terms'),
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
      PlatformDataField(
          name: 'source',
          label: AppLocalizations.t('source'),
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
    searchController = PlatformReactiveFormController(searchDataField);
  }

  refresh(String tsCode, {List<dynamic>? terms, List<dynamic>? source}) async {
    Map<String, dynamic> responseData = await remoteQStatService
        .sendFindQStatBy(tsCode: tsCode, terms: terms, source: source);
    var count = responseData['count'];
    List<QStat> qstats = responseData['data'];
    qstatController.replaceAll(qstats);
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
    Widget platformReactiveForm = Container(
        padding: const EdgeInsets.all(10.0),
        child: PlatformReactiveForm(
            height: appDataProvider.portraitSize.height * 0.5,
            spacing: 5.0,
            platformReactiveFormController: searchController,
            onSubmit: (Map<String, dynamic> values) {
              _onSubmit(context, values);
            }));

    platformReactiveForm = ExpansionTile(
      title: Text(AppLocalizations.t('Search')),
      initiallyExpanded: true,
      controller: expansibleController,
      children: [platformReactiveForm],
    );

    return platformReactiveForm;
  }

  _onSubmit(BuildContext context, Map<String, dynamic> values) async {
    String? tsCode = values['tsCode'];
    if (tsCode == null) {
      DialogUtil.error(content: 'tsCode must be value');
      return;
    }
    await refresh(tsCode,
        terms: values['terms']?.toList(), source: values['source']?.toList());
    expansibleController.collapse();
    DialogUtil.info(content: AppLocalizations.t('QStat search completely'));
  }

  Widget _buildQStatListView(BuildContext context) {
    final List<PlatformDataColumn> qstatDataColumns = [
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
        label: AppLocalizations.t('source'),
        name: 'source',
        width: 80,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('pe'),
        name: 'pe',
        width: 50,
        dataType: DataType.double,
        align: Alignment.centerRight,
        onSort: (int index, bool ascending) =>
            qstatController.sort((t) => t.pe, index, 'pe', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('peg'),
        name: 'peg',
        width: 70,
        dataType: DataType.double,
        align: Alignment.centerRight,
        onSort: (int index, bool ascending) =>
            qstatController.sort((t) => t.peg, index, 'peg', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('close'),
        name: 'close',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 80,
        onSort: (int index, bool ascending) =>
            qstatController.sort((t) => t.close, index, 'close', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('pctChgClose'),
        name: 'pct_chg_close',
        dataType: DataType.percentage,
        align: Alignment.centerRight,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        width: 80,
        onSort: (int index, bool ascending) => qstatController.sort(
            (t) => t.pctChgClose, index, 'pctChgClose', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('yoySales'),
        name: 'yoy_sales',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 100,
        onSort: (int index, bool ascending) => qstatController.sort(
            (t) => t.yoySales, index, 'yoySales', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('yoyDeduNp'),
        name: 'yoy_dedu_np',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 110,
        onSort: (int index, bool ascending) => qstatController.sort(
            (t) => t.yoyDeduNp, index, 'yoyDeduNp', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('orLastMonth'),
        name: 'or_last_month',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 110,
        onSort: (int index, bool ascending) => qstatController.sort(
            (t) => t.orLastMonth, index, 'orLastMonth', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('npLastMonth'),
        name: 'np_last_month',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 130,
        onSort: (int index, bool ascending) => qstatController.sort(
            (t) => t.npLastMonth, index, 'npLastMonth', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('weightAvgRoe'),
        name: 'weight_avg_roe',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 100,
        onSort: (int index, bool ascending) => qstatController.sort(
            (t) => t.weightAvgRoe, index, 'weightAvgRoe', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('grossProfitMargin'),
        name: 'gross_profit_margin',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 80,
        onSort: (int index, bool ascending) => qstatController.sort(
            (t) => t.grossProfitMargin, index, 'grossProfitMargin', ascending),
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          inputType: InputType.custom,
          buildSuffix: _buildActionWidget),
    ];

    searchController.setValue(
        'startDate', DateUtil.formatDateQuarter(DateTime.now()));
    return BindingTrinaDataGrid<QStat>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: qstatDataColumns,
      controller: qstatController,
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
