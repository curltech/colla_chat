import 'package:colla_chat/entity/stock/day_line.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/entity/stock/share_group.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/stock_line_chart_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/stock/day_line.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/service/stock/share_group.dart';
import 'package:colla_chat/service/stock/stock_line.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 自选股当前日线的控制器
final DataListController<DayLine> dayLineController =
    DataListController<DayLine>();

///自选股和分组的查询界面
class ShareSelectionWidget extends StatelessWidget with TileDataMixin {
  final StockLineChartWidget stockLineChartWidget = StockLineChartWidget();

  ShareSelectionWidget({super.key}) {
    indexWidgetProvider.define(stockLineChartWidget);
    _buildGroupSubscription().then((dynamic) {
      _refresh(groupName.value);
    });
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'my_selection';

  @override
  IconData get iconData => Icons.featured_play_list_outlined;

  @override
  String get title => 'MySelection';

  RxString groupName =
      AppLocalizations.t(shareGroupService.defaultGroupName).obs;

  RxMap<String, String> groupSubscription = <String, String>{}.obs;

  _buildGroupSubscription() async {
    Map<String, String> groupSubscription = {};
    String defaultGroupName =
        AppLocalizations.t(shareGroupService.defaultGroupName);
    groupSubscription[defaultGroupName] = shareService.subscription;
    groupSubscription.addAll(await shareGroupService.groupSubscription);

    return this.groupSubscription.value = groupSubscription;
  }

  Widget _buildActionWidget(BuildContext context, int index, dynamic dayLine) {
    Widget actionWidget = Row(
      children: [
        const SizedBox(
          width: 10,
        ),
        IconButton(
          onPressed: () async {
            String tsCode = dayLine.tsCode;
            String groupName = this.groupName.value;
            String defaultGroupName =
                AppLocalizations.t(shareGroupService.defaultGroupName);
            if (groupName != defaultGroupName) {
              bool? confirm = await DialogUtil.confirm(
                  content: 'Do you confirm remove from group?');
              if (confirm != null && confirm) {
                await shareGroupService.remove(groupName, tsCode);
                _buildGroupSubscription();
                dayLineController.delete(index: index);
              }
            }
          },
          icon: const Icon(
            Icons.group_remove,
            color: Colors.yellow,
          ),
          tooltip: AppLocalizations.t('Remove from group'),
        ),
        IconButton(
          onPressed: () async {
            String tsCode = dayLine.tsCode;
            Share? share = await shareService.findShare(tsCode);
            String name = share?.name ?? '';
            multiStockLineController.put(tsCode, name);
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

  /// 如果此时有记录被选择，则选择的记录将被移入组中
  _addMember(String groupName) async {
    List<DayLine> checked = dayLineController.checked;
    if (checked.isNotEmpty) {
      List<String> tsCodes = [];
      for (DayLine dayLine in checked) {
        tsCodes.add(dayLine.tsCode);
      }
      await shareGroupService.add(groupName, tsCodes);
      _buildGroupSubscription();
    }
  }

  _refresh(String groupName) async {
    String? subscription = groupSubscription.value[groupName];
    if (subscription == null || subscription.isEmpty) {
      dayLineController.replaceAll([]);
      multiStockLineController.replaceAll([]);
      return;
    }
    List<String> tsCodes = subscription.split(',');
    for (var tsCode in tsCodes) {
      /// 更新股票的日线的数据
      stockLineService.getUpdateDayLine(tsCode);
    }
    List<DayLine> dayLines =
        await remoteDayLineService.sendFindLatest(subscription);
    dayLineController.replaceAll(dayLines);
    tsCodes.clear();
    for (var dayLine in dayLines) {
      tsCodes.add(dayLine.tsCode);
    }
    multiStockLineController.replaceAll(tsCodes);
  }

  Widget _buildShareListView(BuildContext context) {
    final List<PlatformDataColumn> dayLineDataColumns = [
      PlatformDataColumn(
        label: '股票代码',
        name: 'ts_code',
        width: 80,
      ),
      PlatformDataColumn(
        label: '股票名',
        name: 'name',
        width: 80,
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
        align: TextAlign.right,
        width: 70,
      ),
      PlatformDataColumn(
        label: '涨幅',
        name: 'pct_chg_close',
        dataType: DataType.percentage,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: TextAlign.right,
        width: 70,
      ),
      PlatformDataColumn(
        label: '量变化',
        name: 'pct_chg_vol',
        dataType: DataType.percentage,
        positiveColor: Colors.red,
        negativeColor: Colors.green,
        align: TextAlign.right,
        width: 70,
      ),
      PlatformDataColumn(
        label: '换手率',
        name: 'turnover',
        dataType: DataType.double,
        align: TextAlign.right,
        width: 70,
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          inputType: InputType.custom,
          buildSuffix: (int index, dynamic dayLine) {
            return _buildActionWidget(context, index, dayLine);
          }),
    ];
    return Obx(
      () {
        return BindingDataTable2<DayLine>(
          key: UniqueKey(),
          showCheckboxColumn: true,
          horizontalMargin: 10.0,
          columnSpacing: 0.0,
          platformDataColumns: dayLineDataColumns,
          controller: dayLineController,
          fixedLeftColumns: 2,
        );
      },
    );
  }

  Widget _buildShareGroupWidget() {
    return Obx(() {
      List<Widget> children = [];
      for (String key in groupSubscription.keys) {
        children.add(TextButton(
          onPressed: () {
            _addMember(key);
            groupName.value = key;
            _refresh(key);
          },
          child: ValueListenableBuilder(
              valueListenable: groupName,
              builder: (BuildContext context, String groupName, Widget? child) {
                return Text(key,
                    style: TextStyle(
                        color: groupName != key ? Colors.white : null));
              }),
        ));
      }
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children));
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      IconButton(
        tooltip: AppLocalizations.t('Add share'),
        onPressed: () {
          indexWidgetProvider.push('add_share');
        },
        icon: const Icon(Icons.add_circle_outline),
      ),
      IconButton(
        tooltip: AppLocalizations.t('Add group'),
        onPressed: () async {
          String? groupName = await DialogUtil.showTextFormField(
              title: 'Add group', content: 'Group name');
          if (groupName != null) {
            await shareGroupService.store(ShareGroup(groupName));
          }
        },
        icon: const Icon(Icons.group),
      ),
      IconButton(
        tooltip: AppLocalizations.t('Refresh'),
        onPressed: () {
          _refresh(groupName.value);
        },
        icon: const Icon(Icons.refresh),
      ),
    ];
    return AppBarView(
      title: title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: Column(
        children: [
          _buildShareGroupWidget(),
          Expanded(child: _buildShareListView(context))
        ],
      ),
    );
  }
}
