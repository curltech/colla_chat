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
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

///自选股和分组的查询界面
class PerformanceWidget extends StatelessWidget with DataTileMixin {
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

  final DataListController<Performance> performanceController =
      DataListController<Performance>();

  late final List<PlatformDataColumn> performanceDataColumns = [
    PlatformDataColumn(
      label: AppLocalizations.t('securityCode'),
      name: 'security_code',
      align: Alignment.centerRight,
      width: 120,
    ),
    PlatformDataColumn(
      label: AppLocalizations.t('dataType'),
      name: 'data_type',
      width: 100,
    ),
    PlatformDataColumn(
      label: AppLocalizations.t('securityNameAbbr'),
      name: 'security_name_abbr',
      width: 80,
    ),
    PlatformDataColumn(
      label: AppLocalizations.t('qDate'),
      name: 'qdate',
      width: 60,
    ),
    PlatformDataColumn(
      label: AppLocalizations.t('yoySales'),
      name: 'yoy_sales',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: Alignment.centerRight,
      width: 100,
      onSort: (int index, bool ascending) => performanceController.sort(
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
      onSort: (int index, bool ascending) => performanceController.sort(
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
      onSort: (int index, bool ascending) => performanceController.sort(
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
      onSort: (int index, bool ascending) => performanceController.sort(
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
      onSort: (int index, bool ascending) => performanceController.sort(
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
      onSort: (int index, bool ascending) => performanceController.sort(
          (t) => t.grossProfitMargin, index, 'grossProfitMargin', ascending),
    ),
    PlatformDataColumn(
      label: AppLocalizations.t('basicEps'),
      name: 'basic_eps',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: Alignment.centerRight,
      width: 110,
      onSort: (int index, bool ascending) => performanceController.sort(
          (t) => t.basicEps, index, 'basicEps', ascending),
    ),
    PlatformDataColumn(
      label: AppLocalizations.t('totalOperateIncome'),
      name: 'total_operate_income',
      dataType: DataType.double,
      align: Alignment.centerRight,
      width: 140,
      onSort: (int index, bool ascending) => performanceController.sort(
          (t) => t.totalOperateIncome, index, 'totalOperateIncome', ascending),
    ),
    PlatformDataColumn(
      label: AppLocalizations.t('parentNetProfit'),
      name: 'parent_net_profit',
      dataType: DataType.double,
      positiveColor: Colors.red,
      negativeColor: Colors.green,
      align: Alignment.centerRight,
      width: 140,
      onSort: (int index, bool ascending) => performanceController.sort(
          (t) => t.parentNetProfit, index, 'parentNetProfit', ascending),
    ),
    PlatformDataColumn(
        label: '',
        name: 'action',
        inputType: InputType.custom,
        buildSuffix: _buildActionWidget),
  ];
  late final List<PlatformDataField> searchDataField;
  late final PlatformReactiveFormController searchController;
  final ExpansibleController expansibleController = ExpansibleController();

  void _init() {
    searchDataField = [
      PlatformDataField(
        name: 'securityCode',
        label: AppLocalizations.t('securityCode'),
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
        validators: [Validators.required],
        validationMessages: {
          ValidationMessage.required: (_) =>
              'The securityCode must not be empty',
        },
      ),
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
    ];
    searchController = PlatformReactiveFormController(searchDataField);
  }

  Future<void> refresh(String securityCode, String startDate) async {
    Map<String, dynamic> responseData = await remotePerformanceService
        .sendFindByQDate(securityCode: securityCode, startDate: startDate);
    var count = responseData['count'];
    List<Performance> performances = responseData['data'];
    performanceController.replaceAll(performances);
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

  /// 构建搜索条件
  Widget _buildSearchView(BuildContext context) {
    Widget platformReactiveForm = Container(
        padding: const EdgeInsets.all(10.0),
        child: PlatformReactiveForm(
          height: appDataProvider.portraitSize.height * 0.3,
          spacing: 10.0,
          platformReactiveFormController: searchController,
          onSubmit: (Map<String, dynamic> values) {
            _onSubmit(values);
          },
        ));

    platformReactiveForm = ExpansionTile(
      title: Text(AppLocalizations.t('Search')),
      initiallyExpanded: true,
      controller: expansibleController,
      children: [platformReactiveForm],
    );

    return platformReactiveForm;
  }

  Future<void> _onSubmit(Map<String, dynamic> values) async {
    String? securityCode = values['security_code'];
    String? startDate = values['start_date'];
    if (securityCode == null || startDate == null) {
      DialogUtil.error(
          content:
              AppLocalizations.t('securityCode and startDate are not empty'));

      return;
    }
    await refresh(securityCode, startDate);
    expansibleController.collapse();
    DialogUtil.info(
        content: AppLocalizations.t('Performance search completely'));
  }

  Widget _buildPerformanceListView(BuildContext context) {
    searchController.setValue(
        'startDate', DateUtil.formatDateQuarter(DateTime.now()));
    return BindingTrinaDataGrid<Performance>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: performanceDataColumns,
      controller: performanceController,
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
          Expanded(child: _buildPerformanceListView(context))
        ],
      ),
    );
  }
}
