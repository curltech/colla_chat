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
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/style/platform_style_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 存储在本地的自选股票的代码和分组
class MyShareController {
  final RxBool showLoading = false.obs;

  /// 自选股
  final RxString subscription = ''.obs;

  /// 当前组
  final RxString groupName = ShareGroupService.defaultGroupName.obs;

  /// 组的自选股
  final RxMap<String, String> groupSubscription = <String, String>{}.obs;

  MyShareController() {
    _init();
  }

  _init() async {
    String? value =
        await localSharedPreferences.get('subscription', encrypt: true);
    subscription.value = value ?? '';
    if (subscription.value.endsWith(",")) {
      subscription.value =
          subscription.value.substring(0, subscription.value.length - 1);
    }
    List<String> tsCodes = subscription.value.split(',');
    for (String tsCode in tsCodes) {
      if (tsCode.isEmpty) {
        continue;
      }
      await multiKlineController.put(tsCode);
    }

    await assignGroupSubscription();
  }

  /// 新股票加入自选股
  Future<void> add(Share share) async {
    await shareService.store(share);
    String tsCode = share.tsCode!;
    if (!subscription.contains(tsCode)) {
      if (subscription.value.endsWith(',')) {
        subscription.value += tsCode;
      } else {
        subscription.value += ',$tsCode';
      }
      await localSharedPreferences.save('subscription', subscription.value,
          encrypt: true);
    }
    String defaultGroupName =
        AppLocalizations.t(ShareGroupService.defaultGroupName);
    groupSubscription[defaultGroupName] = subscription.value;
  }

  /// 删除股票，并从各各分组中删除
  Future<void> remove(String tsCode) async {
    if (subscription.contains(',$tsCode')) {
      subscription.value = subscription.replaceAll(',$tsCode', '');
    }
    if (subscription.contains(tsCode)) {
      subscription.value = subscription.replaceAll(tsCode, '');
    }
    await localSharedPreferences.save('subscription', subscription.value,
        encrypt: true);
    for (String groupName in groupSubscription.keys) {
      await removeMember(groupName, tsCode);
    }
  }

  /// 初始化各个分组和股票
  Future<void> assignGroupSubscription() async {
    Map<String, String> groupSubscription = {};
    String defaultGroupName =
        AppLocalizations.t(ShareGroupService.defaultGroupName);
    groupSubscription[defaultGroupName] = subscription.value;
    try {
      myShareController.showLoading.value = true;
      List<ShareGroup> shareGroups = await shareGroupService.findAll();
      myShareController.showLoading.value = false;
      for (var shareGroup in shareGroups) {
        if (defaultGroupName == shareGroup.groupName) {
          continue;
        }
        String subscription = shareGroup.subscription;
        if (subscription.endsWith(",")) {
          subscription = subscription.substring(0, subscription.length - 1);
        }
        groupSubscription[shareGroup.groupName] = subscription;
      }
    } catch (e) {
      myShareController.showLoading.value = false;
    }

    this.groupSubscription.assignAll(groupSubscription);
  }

  /// 查询分组的股票
  Future<String?> findSubscription(String groupName) async {
    String? subscription = groupSubscription[groupName];
    if (subscription == null) {
      String defaultGroupName =
          AppLocalizations.t(ShareGroupService.defaultGroupName);
      if (defaultGroupName == groupName) {
        subscription = myShareController.subscription.value;
        groupSubscription[groupName] = subscription;
      } else {
        try {
          myShareController.showLoading.value = true;
          ShareGroup? shareGroup = await shareGroupService
              .findOne(where: 'groupName=?', whereArgs: [groupName]);
          myShareController.showLoading.value = false;
          if (shareGroup != null) {
            groupSubscription[groupName] = shareGroup.subscription;
          } else {
            groupSubscription[groupName] = '';
          }
        } catch (e) {
          myShareController.showLoading.value = false;
        }
      }
    }
    return subscription;
  }

  /// 删除分组，自选股分组不能删除
  removeGroup(String groupName) async {
    String defaultGroupName =
        AppLocalizations.t(ShareGroupService.defaultGroupName);
    if (defaultGroupName != groupName) {
      groupSubscription.remove(groupName);
      if (this.groupName.value == groupName) {
        this.groupName.value = defaultGroupName;
      }
      shareGroupService.delete(where: 'groupName=?', whereArgs: [groupName]);
    }
  }

  /// 将股票加入分组
  Future<bool> addMember(String groupName, List<String> tsCodes) async {
    String? subscription = groupSubscription[groupName];
    subscription ??= '';
    bool result = false;
    for (String tsCode in tsCodes) {
      if (!subscription!.contains(tsCode)) {
        if (subscription.endsWith(',')) {
          subscription += tsCode;
        } else {
          subscription += ',$tsCode';
        }
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

  /// 从分组中删除股票，不能从自选股分组中删除
  Future<bool> removeMember(String groupName, String tsCode) async {
    String defaultGroupName =
        AppLocalizations.t(ShareGroupService.defaultGroupName);
    if (defaultGroupName == groupName) {
      return false;
    }
    String? subscription = groupSubscription[groupName];
    if (subscription != null) {
      if (subscription.contains(',$tsCode')) {
        subscription = subscription.replaceAll(',$tsCode', '');
      }
      if (subscription.contains(tsCode)) {
        subscription = subscription.replaceAll(tsCode, '');
      }
      groupSubscription[groupName] = subscription;
      ShareGroup shareGroup = ShareGroup(groupName, subscription: subscription);
      await shareGroupService.store(shareGroup);

      return true;
    }
    return false;
  }

  /// 能否增加股票到分组
  Future<bool> canBeAdd(String groupName, String tsCode) async {
    String? subscription = groupSubscription[groupName];
    if (subscription != null && subscription.isNotEmpty) {
      return !subscription.contains(tsCode);
    }
    return true;
  }

  /// 能否从分组删除股票
  Future<bool> canBeRemove(String groupName, String tsCode) async {
    String defaultGroupName =
        AppLocalizations.t(ShareGroupService.defaultGroupName);
    if (defaultGroupName == groupName) {
      return false;
    }
    return !(await canBeAdd(groupName, tsCode));
  }
}

MyShareController myShareController = MyShareController();

///自选股和分组的查询界面
class ShareSelectionWidget extends StatefulWidget with TileDataMixin {
  final StockLineChartWidget stockLineChartWidget = StockLineChartWidget();

  ShareSelectionWidget({super.key}) {
    indexWidgetProvider.define(stockLineChartWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'my_selection';

  @override
  IconData get iconData => Icons.featured_play_list_outlined;

  @override
  String get title => 'MySelection';

  @override
  State<StatefulWidget> createState() => _ShareSelectionWidgetState();
}

class _ShareSelectionWidgetState extends State<ShareSelectionWidget>
    with TickerProviderStateMixin {
  final DataListController<DayLine> dayLineController =
      DataListController<DayLine>();
  TabController? tabController;

  @override
  initState() {
    super.initState();
    myShareController.subscription;
  }

  Widget _buildShareGroupWidget(BuildContext context) {
    final tabBar = ListenableBuilder(
        listenable: myShareController.groupSubscription,
        builder: (context, child) {
          tabController?.dispose();
          tabController = TabController(
              length: myShareController.groupSubscription.length, vsync: this);
          final List<Tab> tabs = <Tab>[];
          int index = 0;
          List<String> groupNames =
              myShareController.groupSubscription.keys.toList();
          for (int i = 0; i < groupNames.length; ++i) {
            String groupName = groupNames[i];
            tabs.add(Tab(
              text: groupName,
              iconMargin: const EdgeInsets.all(0.0),
            ));
            if (groupName == myShareController.groupName.value) {
              index = i;
            }
          }
          tabController!.index = index;
          return TabBar(
            tabs: tabs,
            controller: tabController,
            isScrollable: true,
            indicatorColor: Colors.amberAccent,
            labelColor: Colors.amberAccent,
            unselectedLabelColor: Colors.white,
            dividerColor: Colors.white.withAlpha(0),
            padding: const EdgeInsets.all(0.0),
            labelPadding: const EdgeInsets.fromLTRB(0, 0, 15.0, 0),
            onTap: (int index) async {
              Tab tab = tabs[index];
              String groupName = tab.text!;
              await _addMember(groupName);
              myShareController.groupName.value = groupName;
              _refresh();
            },
          );
        });
    return tabBar.asStyle(blur: 128);
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

  /// 如果此时有记录被选择，则选择的记录将被移入组中
  _addMember(String groupName) async {
    List<DayLine> dayLines = dayLineController.selected;
    if (dayLines.isEmpty) {
      return;
    }
    bool? confirm = await DialogUtil.confirm(
        content:
            'Do you confirm add selected ${dayLines.length} shares to group:$groupName?');
    if (confirm == null || !confirm) {
      return;
    }
    dayLineController.unselectAll();
    List<String> tsCodes = [];
    for (DayLine dayLine in dayLines) {
      tsCodes.add(dayLine.tsCode);
    }
    await myShareController.addMember(groupName, tsCodes);
  }

  _removeMember() async {
    String groupName = myShareController.groupName.value;
    String defaultGroupName =
        AppLocalizations.t(ShareGroupService.defaultGroupName);

    List<DayLine> dayLines = dayLineController.selected;
    if (dayLines.isEmpty) {
      return;
    }
    bool? confirm = await DialogUtil.confirm(
        content:
            'Do you confirm remove selected ${dayLines.length} shares from group:$groupName?');
    if (confirm == null || !confirm) {
      return;
    }
    dayLineController.unselectAll();
    for (var dayLine in dayLines) {
      String tsCode = dayLine.tsCode;
      if (groupName == defaultGroupName) {
        await myShareController.remove(tsCode);
        multiKlineController.remove(tsCode);
        _refresh();
      } else {
        await myShareController.removeMember(groupName, tsCode);
        _refresh();
      }
    }
  }

  _removeShare() async {
    List<DayLine> dayLines = dayLineController.selected;
    if (dayLines.isEmpty) {
      return;
    }
    bool? confirm = await DialogUtil.confirm(
        content: 'Do you confirm remove selected ${dayLines.length} shares?');
    if (confirm != null && confirm) {
      dayLineController.unselectAll();
      for (var dayLine in dayLines) {
        await myShareController.remove(dayLine.tsCode);
      }
      _refresh();
    }
  }

  _refresh({String? groupName}) async {
    groupName ??= myShareController.groupName.value;
    String? subscription = await myShareController.findSubscription(groupName);
    if (subscription != null) {
      List<String> tsCodes = subscription.split(',');
      try {
        myShareController.showLoading.value = true;
        List<DayLine> dayLines =
            await multiKlineController.findLatestDayLines(tsCodes: tsCodes);
        dayLineController.replaceAll(dayLines);
        myShareController.showLoading.value = false;
      } catch (e) {
        myShareController.showLoading.value = false;
      }
    } else {
      dayLineController.replaceAll([]);
    }
  }

  List<PlatformDataColumn> _buildDayLineDataColumns() {
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
        label: AppLocalizations.t('industry'),
        name: 'industry',
        width: 80,
        onSort: (int index, bool ascending) => dayLineController.sort(
            (t) => t.industry, index, 'industry', ascending),
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

    return dayLineDataColumns;
  }

  Widget _buildDayLineListView(BuildContext context) {
    Widget table = BindingTrinaDataGrid<DayLine>(
        key: UniqueKey(),
        showCheckboxColumn: true,
        horizontalMargin: 10.0,
        columnSpacing: 0.0,
        platformDataColumns: _buildDayLineDataColumns(),
        controller: dayLineController,
        fixedLeftColumns: 2,
        minWidth: 700);
    return Stack(children: <Widget>[
      table,
      Obx(() {
        if (myShareController.showLoading.value) {
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

  List<ActionData> _buildShareActions(BuildContext context) {
    List<ActionData> actions = [
      ActionData(
        label: AppLocalizations.t('Add share'),
        onTap: (int index, String label, {String? value}) {
          indexWidgetProvider.push('add_share');
        },
        icon: const Icon(Icons.add_chart_outlined),
      ),
      ActionData(
        label: AppLocalizations.t('Delete share'),
        onTap: (int index, String label, {String? value}) async {
          await _removeShare();
        },
        icon: const Icon(Icons.bookmark_remove),
      ),
      ActionData(
        label: AppLocalizations.t('Remove member'),
        onTap: (int index, String label, {String? value}) async {
          await _removeMember();
        },
        icon: const Icon(Icons.remove_road_outlined),
      ),
      ActionData(
        label: AppLocalizations.t('Add group'),
        onTap: (int index, String label, {String? value}) async {
          String? groupName = await DialogUtil.showTextFormField(
              title: 'Add group', content: 'Group name');
          if (groupName != null) {
            await shareGroupService.store(ShareGroup(groupName));
            myShareController.groupSubscription[groupName] = '';
          }
        },
        icon: const Icon(Icons.group_add_outlined),
      ),
      ActionData(
        label: AppLocalizations.t('Delete group'),
        onTap: (int index, String label, {String? value}) async {
          String groupName = myShareController.groupName.value;
          bool? confirm = await DialogUtil.confirm(
              content: 'Do you confirm remove group $groupName?');
          if (confirm != null && confirm) {
            await myShareController.removeGroup(groupName);
            _refresh();
          }
        },
        icon: const Icon(Icons.group_remove_outlined),
      ),
      ActionData(
        label: AppLocalizations.t('Refresh'),
        onTap: (int index, String label, {String? value}) async {
          _refresh();
        },
        icon: const Icon(Icons.refresh),
      ),
    ];

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    _refresh();
    return AppBarView(
      title: widget.title,
      helpPath: widget.routeName,
      withLeading: true,
      actions: _buildShareActions(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShareGroupWidget(context),
          Expanded(child: _buildDayLineListView(context))
        ],
      ),
    );
  }
}
