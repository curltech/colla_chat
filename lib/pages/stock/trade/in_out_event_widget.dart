import 'package:colla_chat/entity/stock/day_line.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/dayline_chart_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/stock/day_line.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
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

  @override
  initState() {
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

  refresh() async {
    String? eventCode = inoutEventController.eventCode;
    if (eventCode != null) {
      int tradeDate = DateUtil.formatDateInt(DateUtil.currentDateTime());
      List<DayLine> dayLines =
          await remoteDayLineService.sendFindInout(eventCode, tradeDate: tradeDate);
      inoutEventController.replaceAll(dayLines);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      IconButton(
        tooltip: AppLocalizations.t('Refresh inout event'),
        onPressed: () async {
          await refresh();
        },
        icon: const Icon(Icons.refresh_outlined),
      ),
    ];
    return AppBarView(
        title: widget.title,
        withLeading: true,
        rightWidgets: rightWidgets,
        child: _buildInOutEventListView(context));
  }

  @override
  void dispose() {
    inoutEventController.removeListener(_update);
    super.dispose();
  }
}
