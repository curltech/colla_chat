import 'package:colla_chat/entity/stock/day_line.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/entity/stock/share_group.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/stock_line_chart_widget.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/service/stock/share_group.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 存储在本地的自选股票的代码和分组
class MyShareController {
  final RxBool showLoading = false.obs;
  final RxString subscription = ''.obs;

  final RxString groupName =
      AppLocalizations.t(ShareGroupService.defaultGroupName).obs;

  final RxMap<String, String> groupSubscription = <String, String>{}.obs;

  MyShareController() {
    _init();
  }

  _init() async {
    String? value =
        await localSharedPreferences.get('subscription', encrypt: true);
    subscription.value = value ?? '';
    List<String> tsCodes = subscription.value.split(',');
    for (String tsCode in tsCodes) {
      await multiKlineController.put(tsCode);
    }

    await assignGroupSubscription();
  }

  Future<void> add(Share share) async {
    await shareService.store(share);
    String tsCode = share.tsCode!;
    if (!subscription.contains(tsCode)) {
      subscription.value += '$tsCode,';
      await localSharedPreferences.save('subscription', subscription.value,
          encrypt: true);
    }
    String defaultGroupName =
        AppLocalizations.t(ShareGroupService.defaultGroupName);
    await addShareGroup(defaultGroupName, [tsCode]);
  }

  Future<void> remove(String tsCode) async {
    if (subscription.contains(tsCode)) {
      subscription.replaceAll('$tsCode,', '');
      await localSharedPreferences.save('subscription', subscription.value,
          encrypt: true);
    }
  }

  Future<void> assignGroupSubscription() async {
    Map<String, String> groupSubscription = {};
    String defaultGroupName =
        AppLocalizations.t(ShareGroupService.defaultGroupName);
    groupSubscription[defaultGroupName] = subscription.value;
    List<ShareGroup> shareGroups = await shareGroupService.findAll();
    for (var shareGroup in shareGroups) {
      groupSubscription[shareGroup.groupName] = shareGroup.subscription;
    }

    this.groupSubscription.assignAll(groupSubscription);
  }

  Future<String?> findSubscription(String groupName) async {
    String? subscription = groupSubscription[groupName];
    if (subscription == null) {
      if (ShareGroupService.defaultGroupName == groupName) {
        subscription = myShareController.subscription.value;
        groupSubscription[groupName] = subscription;
      } else {
        List<ShareGroup> shareGroups = await shareGroupService
            .find(where: 'groupName=?', whereArgs: [groupName]);
        if (shareGroups.isNotEmpty) {
          subscription = '';
          for (ShareGroup shareGroup in shareGroups) {
            subscription = '${shareGroup.subscription}${subscription!},';
          }
          groupSubscription[groupName] = subscription!;
        }
      }
    }
    return subscription;
  }

  removeGroup(String groupName) async {
    groupSubscription.remove(groupName);
    shareGroupService.delete(where: 'groupName=?', whereArgs: [groupName]);
  }

  Future<bool> addShareGroup(String groupName, List<String> tsCodes) async {
    String? subscription = groupSubscription[groupName];
    subscription ??= '';
    bool result = false;
    for (String tsCode in tsCodes) {
      if (!subscription!.contains(tsCode)) {
        subscription = '$subscription$tsCode,';
        groupSubscription[groupName] = subscription;
        result = true;
      }
    }
    if (result) {
      ShareGroup shareGroup =
          ShareGroup(groupName, subscription: subscription!);
      await shareGroupService.store(shareGroup);

      return true;
    }
    return false;
  }

  Future<bool> removeShareGroup(String groupName, String tsCode) async {
    String? subscription = groupSubscription[groupName];
    if (subscription != null) {
      if (subscription.contains(tsCode)) {
        subscription = subscription.replaceAll('$tsCode,', '');
        groupSubscription[groupName] = subscription;
        ShareGroup shareGroup =
            ShareGroup(groupName, subscription: subscription);
        await shareGroupService.store(shareGroup);

        return true;
      }
    }
    return false;
  }

  Future<bool> canBeAdd(String groupName, String tsCode) async {
    String? subscription = groupSubscription[groupName];
    if (subscription != null && subscription.isNotEmpty) {
      return !subscription.contains(tsCode);
    }
    return true;
  }

  Future<bool> canBeRemove(String groupName, String tsCode) async {
    return !(await canBeAdd(groupName, tsCode));
  }
}

MyShareController myShareController = MyShareController();

///自选股和分组的查询界面
class ShareSelectionWidget extends StatelessWidget with TileDataMixin {
  final StockLineChartWidget stockLineChartWidget = StockLineChartWidget();

  ShareSelectionWidget({super.key}) {
    indexWidgetProvider.define(stockLineChartWidget);
    _refresh();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'my_selection';

  @override
  IconData get iconData => Icons.featured_play_list_outlined;

  @override
  String get title => 'MySelection';

  final DataListController<DayLine> dayLineController =
      DataListController<DayLine>();

  Widget _buildActionWidget(BuildContext context, int index, dynamic dayLine) {
    Widget actionWidget = Row(
      children: [
        const SizedBox(
          width: 10,
        ),
        IconButton(
          onPressed: () async {
            String tsCode = dayLine.tsCode;
            String groupName = myShareController.groupName.value;
            String defaultGroupName =
                AppLocalizations.t(ShareGroupService.defaultGroupName);
            if (groupName != defaultGroupName) {
              bool? confirm = await DialogUtil.confirm(
                  content: 'Do you confirm remove from group?');
              if (confirm != null && confirm) {
                await myShareController.removeShareGroup(groupName, tsCode);
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

  /// 如果此时有记录被选择，则选择的记录将被移入组中
  _addMember(String groupName) async {
    List<DayLine> checked = dayLineController.checked;
    if (checked.isNotEmpty) {
      List<String> tsCodes = [];
      for (DayLine dayLine in checked) {
        tsCodes.add(dayLine.tsCode);
      }
      await myShareController.addShareGroup(groupName, tsCodes);
    }
  }

  _refresh({String? groupName}) async {
    groupName ??= myShareController.groupName.value;
    String? subscription = await myShareController.findSubscription(groupName);
    if (subscription != null) {
      List<String> tsCodes = subscription.split(',');
      List<DayLine> dayLines =
          await multiKlineController.findLatestDayLines(tsCodes: tsCodes);
      dayLineController.replaceAll(dayLines);
    } else {
      dayLineController.replaceAll([]);
    }
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
    return Stack(children: <Widget>[
      BindingDataTable2<DayLine>(
        key: UniqueKey(),
        showCheckboxColumn: true,
        horizontalMargin: 10.0,
        columnSpacing: 0.0,
        platformDataColumns: dayLineDataColumns,
        controller: dayLineController,
        fixedLeftColumns: 2,
      ),
      if (myShareController.showLoading.value)
        Container(
          width: double.infinity,
          height: 450,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
    ]);
  }

  /// 股票分组的按钮
  Widget _buildShareGroupWidget() {
    return Obx(() {
      List<Widget> children = [];
      for (String key in myShareController.groupSubscription.keys) {
        children.add(TextButton(
          onPressed: () {
            _addMember(key);
            myShareController.groupName.value = key;
            _refresh();
          },
          child: Text(key,
              style: TextStyle(
                  backgroundColor: myShareController.groupName.value == key
                      ? Colors.white
                      : null,
                  color: myShareController.groupName.value != key
                      ? Colors.white
                      : null)),
        ));
      }
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal, child: Wrap(children: children));
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
            myShareController.groupSubscription[groupName] = '';
          }
        },
        icon: const Icon(Icons.group),
      ),
      IconButton(
        tooltip: AppLocalizations.t('Refresh'),
        onPressed: () async {
          _refresh();
        },
        icon: const Icon(Icons.refresh),
      ),
    ];
    return AppBarView(
      title: title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShareGroupWidget(),
          Expanded(child: _buildShareListView(context))
        ],
      ),
    );
  }
}
