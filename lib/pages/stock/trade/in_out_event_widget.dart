import 'package:colla_chat/entity/stock/day_line.dart';
import 'package:colla_chat/entity/stock/event_filter.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/dayline_chart_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/day_line.dart';
import 'package:colla_chat/service/stock/event_filter.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

class InoutEventController extends DataListController<DayLine> {
  String? _eventCode;
  String? _eventName;

  /// 当前事件代码
  String? get eventCode {
    return _eventCode;
  }

  String? get eventName {
    return _eventName;
  }

  /// 设置当前事件代码
  setEventCode(String? eventCode, {String? eventName}) {
    if (_eventCode != eventCode) {
      _eventCode = eventCode;
      _eventName = eventName;
      data.clear();
      notifyListeners();
    }
  }
}

final InoutEventController inoutEventController = InoutEventController();

/// 加自选股和分组的查询界面
class InoutEventWidget extends StatefulWidget with TileDataMixin {
  InoutEventWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InoutEventWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'in_out_event';

  @override
  IconData get iconData => Icons.event;

  @override
  String get title => 'InoutEvent';
}

class _InoutEventWidgetState extends State<InoutEventWidget>
    with TickerProviderStateMixin {
  late final List<PlatformDataColumn> inoutEventColumns;
  late final FormInputController searchController;
  ExpansionTileController expansionTileController = ExpansionTileController();

  @override
  initState() {
    final List<PlatformDataField> searchDataField = [
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
        onSort: (int index, bool ascending) =>
            inoutEventController.sort((t) => t.tsCode, index, ascending),
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
        label: '换手率',
        name: 'turnover',
        width: 100,
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          inputType: InputType.custom,
          buildSuffix: _buildActionWidget),
    ];
    searchController = FormInputController(searchDataField);
    inoutEventController.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Widget _buildActionWidget(int index, dynamic dayLine) {
    Widget actionWidget = Row(
      children: [
        IconButton(
          onPressed: () async {
            String tsCode = dayLine.tsCode;
            Share? share = await shareService.findShare(tsCode);
            String name = share?.name ?? '';
            multiDayLineController.put(tsCode, name);
            indexWidgetProvider.push('dayline_chart');
          },
          icon: const Icon(
            Icons.filter,
            color: Colors.yellow,
          ),
        )
      ],
    );
    return actionWidget;
  }

  _onDoubleTap(int index) {
    inoutEventController.currentIndex = index;
  }

  /// 构建搜索条件
  _buildSearchView(BuildContext context) {
    int tradeDate = DateUtil.formatDateInt(DateUtil.currentDateTime());
    searchController.setValues({'tradeDate': tradeDate});
    List<FormButtonDef> formButtonDefs = [
      FormButtonDef(
          label: 'Ok',
          onTap: (Map<String, dynamic> values) {
            _onOk(values);
          }),
    ];
    var formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: appDataProvider.portraitSize.height * 0.4,
          spacing: 5.0,
          controller: searchController,
          formButtonDefs: formButtonDefs,
        ));

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) async {
    String? tsCode = values['tsCode'];
    int? tradeDate = values['tradeDate'];
    int? startDate = values['startDate'];
    int? endDate = values['endDate'];
    refresh(
        tsCode: tsCode,
        tradeDate: tradeDate,
        startDate: startDate,
        endDate: endDate);
    expansionTileController.collapse();
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Inout search completely'));
    }
  }

  Widget _buildInOutEventListView(BuildContext context) {
    return BindingDataTable2<DayLine>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: inoutEventColumns,
      controller: inoutEventController,
      onDoubleTap: _onDoubleTap,
    );
  }

  refresh(
      {String? tsCode, int? tradeDate, int? startDate, int? endDate}) async {
    String? eventCode = inoutEventController.eventCode;
    if (eventCode == null) {
      return;
    }
    //先寻找本地的定制事件代码
    List<EventFilter> eventFilters = await eventFilterService
        .find(where: 'eventCode=?', whereArgs: [eventCode]);
    if (eventFilters.isNotEmpty) {
      String? filterContents;
      List<dynamic>? filterParas;
      for (var eventFilter in eventFilters) {
        String? filterContent = eventFilter.condContent;
        if (filterContent != null) {
          if (filterContents == null) {
            filterContents = filterContent;
          } else {
            filterContents = '$filterContents and $filterContent';
          }
        }
        String? condParas = eventFilter.condParas;
        if (condParas != null) {
          if (filterParas == null) {
            filterParas = JsonUtil.toJson(condParas);
          } else {
            filterParas.addAll(JsonUtil.toJson(condParas));
          }
        }
      }
      if (filterContents != null) {
        List<DayLine> dayLines = await remoteDayLineService.sendFindFlexPoint(
            filterContents,
            tsCode: tsCode,
            tradeDate: tradeDate,
            startDate: startDate,
            endDate: endDate,
            filterParas: filterParas != null
                ? JsonUtil.toJsonString(filterParas)
                : null);
        inoutEventController.replaceAll(dayLines);
      }
    } else {
      List<DayLine> dayLines = await remoteDayLineService.sendFindInout(
          eventCode,
          tsCode: tsCode,
          tradeDate: tradeDate,
          startDate: startDate,
          endDate: endDate);
      inoutEventController.replaceAll(dayLines);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [];
    return AppBarView(
        title: widget.title,
        withLeading: true,
        rightWidgets: rightWidgets,
        child: Column(children: [
          ExpansionTile(
            title: Text(AppLocalizations.t('Search')),
            controller: expansionTileController,
            children: [_buildSearchView(context)],
          ),
          Expanded(child: _buildInOutEventListView(context))
        ]));
  }

  @override
  void dispose() {
    inoutEventController.removeListener(_update);
    super.dispose();
  }
}
