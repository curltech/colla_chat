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
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 查询满足条件的日线数据
class DayLineWidget extends StatelessWidget with TileDataMixin {
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

  late final FormInputController searchController;
  final DataListController<DayLine> dayLineController =
      DataListController<DayLine>();
  final RxBool showLoading = false.obs;
  final ExpansibleController expansibleController = ExpansibleController();

  _init() {
    final List<PlatformDataField> searchDataField = [
      PlatformDataField(
          name: 'tradeDate',
          label: 'TradeDate',
          dataType: DataType.int,
          textInputType: TextInputType.number,
          prefixIcon: Icon(
            Icons.calendar_view_day_outlined,
            color: myself.primary,
          )),
      PlatformDataField(
          name: 'condContent',
          label: 'condContent',
          dataType: DataType.string,
          minLines: 4,
          textInputType: TextInputType.multiline,
          prefixIcon: Icon(
            Icons.content_paste,
            color: myself.primary,
          )),
      PlatformDataField(
          name: 'condParas',
          label: 'condParas',
          dataType: DataType.string,
          minLines: 4,
          textInputType: TextInputType.multiline,
          prefixIcon: Icon(
            Icons.attribution_outlined,
            color: myself.primary,
          )),
    ];
    searchController = FormInputController(searchDataField);
  }

  Widget _buildDayLineView(BuildContext context) {
    final List<PlatformDataColumn> dayLineDataColumns = [
      PlatformDataColumn(
        label: '股票代码',
        name: 'ts_code',
        width: 120,
        onSort: (int index, bool ascending) => dayLineController.sort(
            (t) => t.tsCode, index, 'ts_code', ascending),
      ),
      PlatformDataColumn(
        label: '股票名',
        name: 'name',
        width: 80,
        onSort: (int index, bool ascending) =>
            dayLineController.sort((t) => t.name, index, 'name', ascending),
      ),
      PlatformDataColumn(
        label: '交易日期',
        name: 'trade_date',
        width: 90,
      ),
      PlatformDataColumn(
        label: '收盘价',
        name: 'close',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 70,
      ),
      PlatformDataColumn(
        label: '涨幅',
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
        label: '量变化',
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
        label: '换手率',
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
        controller: dayLineController,
        fixedLeftColumns: 2,
        minWidth: 700);
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
  _buildSearchView(BuildContext context) {
    int tradeDate = DateUtil.formatDateInt(DateUtil.currentDateTime());
    searchController.setValues({'tradeDate': tradeDate});
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
          height: appDataProvider.portraitSize.height * 0.5,
          spacing: 5.0,
          controller: searchController,
          formButtons: formButtonDefs,
        ));

    formInputWidget = ExpansionTile(
      title: Text(AppLocalizations.t('Search')),
      controller: expansibleController,
      children: [formInputWidget],
    );

    return formInputWidget;
  }

  _onOk(BuildContext context, Map<String, dynamic> values) async {
    int? tradeDate = values['tradeDate'];
    String? filterContents = values['filterContents'];
    String? filterParas = values['filterParas'];
    refresh(
        tradeDate: tradeDate!,
        filterContents: filterContents!,
        filterParas: filterParas);
    expansibleController.collapse();
    DialogUtil.info(
        content: AppLocalizations.t('stock dayline search completely'));
  }

  refresh(
      {required int tradeDate,
      required String filterContents,
      String? filterParas}) async {
    DateTime start = DateTime.now();
    List<DayLine> dayLines = await remoteDayLineService.sendFindFlexPoint(
        filterContents,
        tradeDate: tradeDate,
        filterParas:
            filterParas != null ? JsonUtil.toJsonString(filterParas) : null);
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
        withLeading: true,
        rightWidgets: rightWidgets,
        child: Column(children: [
          _buildSearchView(context),
          Expanded(child: _buildDayLineView(context))
        ]));
  }
}
