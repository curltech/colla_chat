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
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reactive_forms/reactive_forms.dart';

///自选股和分组的查询界面
class QPerformanceWidget extends StatelessWidget with DataTileMixin {
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
  final ExpansibleController expansibleController = ExpansibleController();
  final DataListController<QPerformance> qperformanceController =
      DataListController<QPerformance>();
  final RxBool showLoading = false.obs;

  void _init() {
    searchDataField = [
      PlatformDataField(
          name: 'tradeDate',
          label: AppLocalizations.t('tradeDate'),
          dataType: DataType.int,
          cancel: true,
          textInputType: TextInputType.number,
          prefixIcon: Icon(
            Icons.calendar_view_day_outlined,
            color: myself.primary,
          )),
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
          name: 'qDate',
          label: AppLocalizations.t('qDate'),
          cancel: true,
          prefixIcon: Icon(
            Icons.date_range_outlined,
            color: myself.primary,
          )),
      PlatformDataField(
        name: 'condContent',
        label: AppLocalizations.t('condContent'),
        dataType: DataType.string,
        minLines: 4,
        cancel: true,
        textInputType: TextInputType.multiline,
        prefixIcon: IconButton(
          color: myself.primary,
          onPressed: () {
            DialogUtil.popModalBottomSheet(builder: (context) {
              return _buildDayLineChipGroup();
            });
          },
          icon: Icon(Icons.content_paste),
        ),
        validators: [Validators.required],
        validationMessages: {
          ValidationMessage.required: (_) =>
              'The condContent must not be empty',
        },
      )
    ];
    searchController = PlatformReactiveFormController(searchDataField);
  }

  Widget _buildDayLineChipGroup() {
    List<String> dayLineFields = [
      'tsCode',
      'industry',
      'qDate',
      'tradeDate',
      'pe',
      'peg',
      'high',
      'close',
      'pctChgHigh',
      'pctChgClose',
      'pctChgMarketValue',
      'weightAvgRoe',
      'grossProfitMargin',
      'orLastMonth',
      'npLastMonth',
      'yoySales',
      'yoyDeduNp',
      'cfps',
      'dividendYieldRatio',
    ];
    List<Widget> chipChildren = [];
    for (var name in dayLineFields) {
      var chip = ActionChip(
        label: Text(AppLocalizations.t(name),
            style: TextStyle(color: Colors.white)),
        backgroundColor: myself.primary,
        onPressed: () {
          _onActionChip(name);
        },
      );
      chipChildren.add(chip);
    }
    return SingleChildScrollView(
        child: Container(
            padding: EdgeInsets.all(10.0),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              runAlignment: WrapAlignment.start,
              children: chipChildren,
            )));
  }

  void _onActionChip(String name) {
    String? condContent = searchController.values['condContent']?.toString();
    if (condContent == null) {
      condContent = '$name=?';
    } else {
      condContent += ' and $name=?';
    }
    searchController.setValue('condContent', condContent);
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
    searchController.setValue(
        'qDate', DateUtil.formatDateQuarter(DateTime.now()));
    Widget platformReactiveForm = Container(
      padding: const EdgeInsets.all(10.0),
      child: PlatformReactiveForm(
          height: appDataProvider.portraitSize.height * 0.5,
          spacing: 5.0,
          platformReactiveFormController: searchController,
          onSubmit: (Map<String, dynamic> values) {
            _onSubmit(context, values);
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

  Future<void> _onSubmit(BuildContext context, Map<String, dynamic> values) async {
    String? tsCode = values['tsCode'];
    int? tradeDate = values['tradeDate'];
    String? qDate = values['qDate'];
    String? condContent = values['condContent'];
    query(
        tradeDate: tradeDate!,
        qDate: qDate,
        condContent: condContent!,
        tsCode: tsCode);
    expansibleController.collapse();
    DialogUtil.info(
        content: AppLocalizations.t('stock qperformance query completely'));
  }

  Future<void> query({
    String? tsCode,
    String? qDate,
    int? tradeDate,
    String? condContent,
  }) async {
    List<QPerformance> qperformances =
        await remoteQPerformanceService.sendFindByCondContent(
            condContent: condContent,
            qDate: qDate,
            tsCode: tsCode,
            tradeDate: tradeDate);
    qperformanceController.replaceAll(qperformances);
    List<String> tsCodes = [];
    for (QPerformance qperformance in qperformances) {
      tsCodes.add(qperformance.tsCode!);
    }
    multiKlineController.replaceAll(tsCodes);
  }

  Widget _buildQPerformanceListView(BuildContext context) {
    final List<PlatformDataColumn> qperformanceDataColumns = [
      PlatformDataColumn(
        label: AppLocalizations.t('tsCode'),
        name: 'ts_code',
        width: 100,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('securityName'),
        name: 'security_name',
        width: 80,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('qDate'),
        name: 'qdate',
        width: 90,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('tradeDate'),
        name: 'trade_date',
        width: 80,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('pe'),
        name: 'pe',
        width: 50,
        dataType: DataType.double,
        align: Alignment.centerRight,
        onSort: (int index, bool ascending) =>
            qperformanceController.sort((t) => t.pe, index, 'pe', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('peg'),
        name: 'peg',
        width: 70,
        dataType: DataType.double,
        align: Alignment.centerRight,
        onSort: (int index, bool ascending) =>
            qperformanceController.sort((t) => t.peg, index, 'peg', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('close'),
        name: 'close',
        dataType: DataType.double,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 80,
        onSort: (int index, bool ascending) => qperformanceController.sort(
            (t) => t.close, index, 'close', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('pctChgClose'),
        name: 'pct_chg_close',
        dataType: DataType.percentage,
        align: Alignment.centerRight,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        width: 80,
        onSort: (int index, bool ascending) => qperformanceController.sort(
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
        onSort: (int index, bool ascending) => qperformanceController.sort(
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
        onSort: (int index, bool ascending) => qperformanceController.sort(
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
        onSort: (int index, bool ascending) => qperformanceController.sort(
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
        onSort: (int index, bool ascending) => qperformanceController.sort(
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
        onSort: (int index, bool ascending) => qperformanceController.sort(
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
        onSort: (int index, bool ascending) => qperformanceController.sort(
            (t) => t.grossProfitMargin, index, 'grossProfitMargin', ascending),
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          inputType: InputType.custom,
          buildSuffix: (int index, dynamic qperformance) {
            return _buildActionWidget(index, qperformance);
          }),
    ];

    Widget table = BindingTrinaDataGrid<QPerformance>(
        key: UniqueKey(),
        showCheckboxColumn: true,
        horizontalMargin: 10.0,
        columnSpacing: 0.0,
        platformDataColumns: qperformanceDataColumns,
        controller: qperformanceController);
    return Stack(children: <Widget>[
      table,
      Obx(() {
        if (showLoading.value) {
          return Container(
            width: double.infinity,
            height: 450,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        } else {
          return nilBox;
        }
      }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [];
    return AppBarView(
      title: title,
      isAppBar: false,
      helpPath: routeName,
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
