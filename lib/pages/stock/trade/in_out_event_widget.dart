import 'package:colla_chat/entity/stock/day_line.dart';
import 'package:colla_chat/entity/stock/event_filter.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/day_line.dart';
import 'package:colla_chat/service/stock/event_filter.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 日线数据列表控制器
class InoutEventController extends DataListController<DayLine> {
  final Rx<String?> _eventCode = Rx<String?>(null);
  final Rx<String?> _eventName = Rx<String?>(null);

  /// 当前事件代码
  String? get eventCode {
    return _eventCode.value;
  }

  String? get eventName {
    return _eventName.value;
  }

  /// 设置当前事件代码
  setEventCode(String? eventCode, {String? eventName}) {
    _eventCode(eventCode);
    _eventName(eventName);
    data.clear();
  }
}

final InoutEventController inoutEventController = InoutEventController();

/// 自定义事件在历史上发生的日线
class InoutEventWidget extends StatelessWidget with TileDataMixin {
  InoutEventWidget({super.key}) {
    _init();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'in_out_event';

  @override
  IconData get iconData => Icons.event;

  @override
  String get title => 'InoutEvent';

  late final List<PlatformDataColumn> inoutEventColumns;
  late final PlatformReactiveFormController searchController;
  final ExpansibleController expansibleController = ExpansibleController();

  _init() {
    final List<PlatformDataField> searchDataField = [
      PlatformDataField(
          name: 'eventCode',
          label: 'EventCode',
          prefixIcon: Icon(
            Icons.event_available_outlined,
            color: myself.primary,
          )),
      PlatformDataField(
          name: 'tsCode',
          label: 'TsCode',
          prefixIcon: Icon(
            Icons.perm_identity_outlined,
            color: myself.primary,
          )),
      PlatformDataField(
          name: 'tradeDate',
          label: 'TradeDate',
          dataType: DataType.int,
          textInputType: TextInputType.number,
          prefixIcon: Icon(
            Icons.code,
            color: myself.primary,
          )),
      PlatformDataField(
          name: 'startDate',
          label: 'StartDate',
          dataType: DataType.int,
          textInputType: TextInputType.number,
          prefixIcon: Icon(
            Icons.type_specimen_outlined,
            color: myself.primary,
          )),
      PlatformDataField(
          name: 'endDate',
          label: 'EndDate',
          dataType: DataType.int,
          textInputType: TextInputType.number,
          prefixIcon: Icon(
            Icons.person,
            color: myself.primary,
          )),
    ];
    inoutEventColumns = [
      PlatformDataColumn(
        label: '股票代码',
        name: 'ts_code',
        width: 100,
        onSort: (int index, bool ascending) => inoutEventController.sort(
            (t) => t.tsCode, index, 'tsCode', ascending),
      ),
      PlatformDataColumn(
        label: '股票名',
        name: 'name',
        width: 100,
      ),
      PlatformDataColumn(
        label: '交易日期',
        name: 'trade_date',
        width: 100,
      ),
      PlatformDataColumn(
        label: '收盘价',
        name: 'close',
        width: 100,
      ),
      PlatformDataColumn(
        label: '涨幅',
        name: 'pct_chg_close',
        dataType: DataType.percentage,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 70,
      ),
      PlatformDataColumn(
        label: '量变化',
        name: 'pct_chg_vol',
        dataType: DataType.percentage,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: Alignment.centerRight,
        width: 90,
      ),
      PlatformDataColumn(
        label: '换手率',
        name: 'turnover',
        dataType: DataType.double,
        align: Alignment.centerRight,
        width: 70,
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          inputType: InputType.custom,
          buildSuffix: _buildActionWidget),
    ];
    searchController = PlatformReactiveFormController(searchDataField);
  }

  Widget _buildActionWidget(int index, dynamic dayLine) {
    Widget actionWidget = Row(
      children: [
        IconButton(
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
        )
      ],
    );
    return actionWidget;
  }

  /// 构建搜索条件
  _buildSearchView(BuildContext context) {
    searchController.values = {'eventCode': inoutEventController.eventCode};
    int tradeDate = DateUtil.formatDateInt(DateUtil.currentDateTime());
    searchController.values = {'tradeDate': tradeDate};
    List<FormButton> formButtonDefs = [
      FormButton(
          label: 'Ok',
          onTap: (Map<String, dynamic> values) {
            _onOk(context, values);
          }),
    ];
    Widget formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: PlatformReactiveForm(
          height: appDataProvider.portraitSize.height * 0.5,
          spacing: 5.0,
          platformReactiveFormController: searchController,
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
    String? eventCode = values['eventCode'];
    String? tsCode = values['tsCode'];
    int? tradeDate = values['tradeDate'];
    int? startDate = values['startDate'];
    int? endDate = values['endDate'];
    refresh(
        eventCode: eventCode,
        tsCode: tsCode,
        tradeDate: tradeDate,
        startDate: startDate,
        endDate: endDate);
    expansibleController.collapse();
    DialogUtil.info(content: AppLocalizations.t('Inout search completely'));
  }

  Widget _buildInOutEventListView(BuildContext context) {
    return BindingTrinaDataGrid<DayLine>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: inoutEventColumns,
      controller: inoutEventController,
    );
  }

  refresh(
      {String? eventCode,
      String? tsCode,
      int? tradeDate,
      int? startDate,
      int? endDate}) async {
    eventCode ??= inoutEventController.eventCode;
    if (eventCode == null) {
      return;
    }
    List<DayLine> dayLines = [];
    //先寻找本地的定制事件代码
    List<EventFilter> eventFilters = await eventFilterService
        .find(where: 'eventCode=?', whereArgs: [eventCode]);
    if (eventFilters.isNotEmpty) {
      String condContent = '1=1';
      List<dynamic>? condParas = [];
      for (var eventFilter in eventFilters) {
        if (eventFilter.condContent != null) {
          condContent = '$condContent and $eventFilter.condContent';
        }
        if (eventFilter.condParas != null) {
          condParas.addAll(JsonUtil.toJson(eventFilter.condParas));
        }
      }
      DateTime start = DateTime.now();
      dayLines = await remoteDayLineService.sendFindByCondContent(condContent,
          tsCode: tsCode,
          tradeDate: tradeDate,
          startDate: startDate,
          endDate: endDate,
          condParas:
              condParas.isNotEmpty ? JsonUtil.toJsonString(condParas) : null);
      DateTime end = DateTime.now();
      logger
          .i('find more data duration:${end.difference(start).inMilliseconds}');
    } else {
      logger.e('eventCode has no filters');

      return;
    }
    inoutEventController.replaceAll(dayLines);
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
          Expanded(child: _buildInOutEventListView(context))
        ]));
  }
}
