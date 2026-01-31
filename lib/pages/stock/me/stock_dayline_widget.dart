import 'package:colla_chat/entity/stock/day_line.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/day_line.dart';
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

/// 查询满足条件的日线数据
class DayLineWidget extends StatelessWidget with DataTileMixin {
  DayLineWidget({super.key}) {
    _init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'dayline';

  @override
  IconData get iconData => Icons.line_axis_outlined;

  @override
  String get title => 'DayLine';

  late final PlatformReactiveFormController searchController;
  final DataListController<DayLine> dayLineController =
      DataListController<DayLine>();
  final RxBool showLoading = false.obs;
  final ExpansibleController expansibleController = ExpansibleController();

  void _init() {
    final List<PlatformDataField> searchDataField = [
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
      'industry',
      'turnover',
      'open',
      'high',
      'low',
      'close',
      'vol',
      'amount',
      'mainNetInflow',
      'smallNetInflow',
      'middleNetInflow',
      'largeNetInflow',
      'superNetInflow',
      'chgClose',
      'pctMainNetInflow',
      'pctSmallNetInflow',
      'pctMiddleNetInflow',
      'pctLargeNetInflow',
      'pctSuperNetInflow',
      'pctChgOpen',
      'pctChgHigh',
      'pctChgLow',
      'pctChgClose',
      'pctChgAmount',
      'pctChgVol',
      'ma3Close',
      'ma5Close',
      'ma10Close',
      'ma13Close',
      'ma20Close',
      'ma21Close',
      'ma30Close',
      'ma34Close',
      'ma55Close',
      'ma60Close',
      'ma90Close',
      'ma120Close',
      'ma144Close',
      'ma233Close',
      'ma240Close',
      'max3Close',
      'max5Close',
      'max10Close',
      'max13Close',
      'max20Close',
      'max21Close',
      'max30Close',
      'max34Close',
      'max55Close',
      'max60Close',
      'max90Close',
      'max120Close',
      'max144Close',
      'max233Close',
      'max240Close',
      'min3Close',
      'min5Close',
      'min10Close',
      'min13Close',
      'min20Close',
      'min21Close',
      'min30Close',
      'min34Close',
      'min55Close',
      'min60Close',
      'min90Close',
      'min120Close',
      'min144Close',
      'min233Close',
      'min240Close',
      'before1Ma3Close',
      'before1Ma5Close',
      'before1Ma10Close',
      'before1Ma13Close',
      'before1Ma20Close',
      'before1Ma21Close',
      'before1Ma30Close',
      'before1Ma34Close',
      'before1Ma55Close',
      'before1Ma60Close',
      'before3Ma3Close',
      'before3Ma5Close',
      'before3Ma10Close',
      'before3Ma13Close',
      'before3Ma20Close',
      'before3Ma21Close',
      'before3Ma30Close',
      'before3Ma34Close',
      'before3Ma55Close',
      'before3Ma60Close',
      'before5Ma3Close',
      'before5Ma5Close',
      'before5Ma10Close',
      'before5Ma13Close',
      'before5Ma20Close',
      'before5Ma21Close',
      'before5Ma30Close',
      'before5Ma34Close',
      'before5Ma55Close',
      'before5Ma60Close',
      'acc3PctChgClose',
      'acc5PctChgClose',
      'acc10PctChgClose',
      'acc13PctChgClose',
      'acc20PctChgClose',
      'acc21PctChgClose',
      'acc30PctChgClose',
      'acc34PctChgClose',
      'acc55PctChgClose',
      'acc60PctChgClose',
      'acc90PctChgClose',
      'acc120PctChgClose',
      'acc144PctChgClose',
      'acc233PctChgClose',
      'acc240PctChgClose',
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

  Widget _buildDayLineView(BuildContext context) {
    final List<PlatformDataColumn> dayLineDataColumns = [
      PlatformDataColumn(
        label: AppLocalizations.t('tsCode'),
        name: 'ts_code',
        width: 120,
        onSort: (int index, bool ascending) => dayLineController.sort(
            (t) => t.tsCode, index, 'ts_code', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('tsName'),
        name: 'name',
        width: 80,
        onSort: (int index, bool ascending) =>
            dayLineController.sort((t) => t.name, index, 'name', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('tradeDate'),
        name: 'trade_date',
        dataType: DataType.int,
        format: '#',
        width: 90,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('close'),
        name: 'close',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 70,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('pctChgClose'),
        name: 'pct_chg_close',
        dataType: DataType.percentage,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 70,
        onSort: (int index, bool ascending) => dayLineController.sort(
            (t) => t.pctChgClose, index, 'pct_chg_close', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('pctChgVol'),
        name: 'pct_chg_vol',
        dataType: DataType.percentage,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 90,
        onSort: (int index, bool ascending) => dayLineController.sort(
            (t) => t.pctChgVol, index, 'pct_chg_vol', ascending),
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('turnover'),
        name: 'turnover',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 70,
        onSort: (int index, bool ascending) => dayLineController.sort(
            (t) => t.turnover, index, 'turnover', ascending),
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          align: Alignment.centerRight,
          width: 70,
          inputType: InputType.custom,
          buildSuffix: (int index, dynamic dayLine) {
            return _buildActionWidget(context, index, dayLine);
          }),
    ];
    Widget table = BindingTrinaDataGrid<DayLine>(
        key: UniqueKey(),
        showCheckboxColumn: true,
        horizontalMargin: 10.0,
        columnSpacing: 0.0,
        platformDataColumns: dayLineDataColumns,
        controller: dayLineController);
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

  Widget _buildActionWidget(BuildContext context, int index, dynamic dayLine) {
    Widget actionWidget = IconButton(
      onPressed: () async {
        String tsCode = dayLine.tsCode;
        await multiKlineController.put(tsCode);
        indexWidgetProvider.push('stockline_chart');
      },
      icon: const Icon(
        Icons.filter,
        color: Colors.yellow,
      ),
      tooltip: AppLocalizations.t('StockLineChart'),
    );
    return actionWidget;
  }

  /// 构建搜索条件
  Widget _buildSearchView(BuildContext context) {
    int tradeDate = DateUtil.formatDateInt(DateUtil.currentDateTime());
    searchController.values = {'tradeDate': tradeDate};
    Widget platformReactiveForm = Container(
      padding: const EdgeInsets.all(10.0),
      child: PlatformReactiveForm(
          height: appDataProvider.portraitSize.height * 0.35,
          spacing: 5.0,
          platformReactiveFormController: searchController,
          onSubmit: (Map<String, dynamic> values) {
            onSubmit(context, values);
          }),
    );

    platformReactiveForm = ExpansionTile(
      title: Text(AppLocalizations.t('Search')),
      controller: expansibleController,
      children: [platformReactiveForm],
    );

    return platformReactiveForm;
  }

  Future<void> onSubmit(BuildContext context, Map<String, dynamic> values) async {
    int? tradeDate = values['tradeDate'];
    String? condContent = values['condContent'];
    query(tradeDate: tradeDate!, condContent: condContent!);
    expansibleController.collapse();
    DialogUtil.info(
        content: AppLocalizations.t('stock dayline query completely'));
  }

  Future<void> query({int? tradeDate, String? condContent}) async {
    DateTime start = DateTime.now();
    List<DayLine> dayLines = await remoteDayLineService.sendFindByCondContent(
        condContent: condContent, tradeDate: tradeDate);
    DateTime end = DateTime.now();
    logger.i(
        'find more day line data duration:${end.difference(start).inMilliseconds}');
    dayLineController.replaceAll(dayLines);
    List<String> tsCodes = [];
    for (DayLine dayLine in dayLines) {
      tsCodes.add(dayLine.tsCode);
    }
    multiKlineController.replaceAll(tsCodes);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [];
    return AppBarView(
        title: title,
        helpPath: routeName,
        isAppBar: false,
        rightWidgets: rightWidgets,
        child: Column(children: [
          _buildSearchView(context),
          Expanded(child: _buildDayLineView(context))
        ]));
  }
}
