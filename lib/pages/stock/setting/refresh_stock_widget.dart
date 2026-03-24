import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/service/stock/stock_line.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/list_map_notifier.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:flutter/material.dart';

/// 运行后台批处理，刷新数据，针对所有的股票
class RefreshStockWidget extends StatelessWidget with DataTileMixin {
  RefreshStockWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'refresh_stock';

  @override
  IconData get iconData => Icons.refresh;

  @override
  String get title => 'RefreshStock';

  final TextEditingController _startDateTextController =
      TextEditingController();
  final ListNotifier<DataTile> tileData =
      ListNotifier<DataTile>([]);

  void _initTileData(BuildContext context) {
    tileData.value = [
      DataTile(
          title: '调度',
          subtitle: '获取数据，汇总，计算评分',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            stockLineService.schedule();
            return null;
          }),
      DataTile(
          title: '所有股票今天日线',
          subtitle: '刷新所有股票今天的日线数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            int? startDate;
            if (_startDateTextController.text.isNotEmpty) {
              startDate = int.parse(_startDateTextController.text);
              stockLineService.refreshTodayLine(startDate: startDate);
            } else {
              stockLineService.refreshTodayLine();
            }
            return null;
          }),
      DataTile(
          title: '分钟线',
          subtitle: '刷新所有股票的分钟线数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            stockLineService.refreshMinLine();
            return null;
          }),
      DataTile(
          title: '所有股票今天分钟线',
          subtitle: '刷新所有股票今天的分钟线数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            stockLineService.refreshTodayMinLine();
            return null;
          }),
      DataTile(
          title: '季度业绩汇总',
          subtitle: '汇总所有股票的季度业绩数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            stockLineService.refreshQPerformance();
            return null;
          }),
      DataTile(
          title: '季度业绩统计汇总',
          subtitle: '汇总所有股票的季度业绩统计数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            stockLineService.refreshQStat();
            return null;
          }),
      DataTile(
          title: '季度业绩评分汇总',
          subtitle: '汇总所有股票的季度业绩评分数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            stockLineService.refreshStatScore();
            return null;
          }),
      DataTile(
          title: '季度业绩分位评分汇总',
          subtitle: '汇总所有股票的季度业绩分位评分数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            stockLineService.createScorePercentile();
            return null;
          }),
      DataTile(
          title: '日线统计',
          subtitle: '计算所有股票的日线统计数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_startDateTextController.text.isNotEmpty) {
              int startDate = int.parse(_startDateTextController.text);
              stockLineService.refreshStat(startDate: startDate);
            }
            return null;
          }),
      DataTile(
          title: '过去1,3,5日线均线',
          subtitle: '计算所有股票的过去1,3,5日线均线统计数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_startDateTextController.text.isNotEmpty) {
              int startDate = int.parse(_startDateTextController.text);
              stockLineService.refreshBeforeMa(startDate: startDate);
            }
            return null;
          }),
      DataTile(
          title: '计算所有股票的买卖点事件',
          subtitle: '计算所有股票的买卖点事件',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            stockLineService.refreshEventCond();
            return null;
          }),
      DataTile(
          title: '更新股票信息',
          subtitle: '更新股票信息',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            stockLineService.updateShares();
            return null;
          }),
      DataTile(
          title: '创建模型数据文件',
          subtitle: '创建模型数据文件',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context: context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_startDateTextController.text.isNotEmpty) {
              int startDate = int.parse(_startDateTextController.text);
              stockLineService.writeAllFile(startDate: startDate);
            }
            return null;
          })
    ];
  }

  Widget _buildRefreshStockView(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        child: AutoSizeTextField(
            controller: _startDateTextController,
            keyboardType: TextInputType.number,
            decoration: buildInputDecoration(
                labelText: AppLocalizations.t('startDate'))),
      ),
      Expanded(
        child: ValueListenableBuilder(
            valueListenable: tileData.listenable,
            builder: (context, value, _) {
              return DataListView(
                itemCount: tileData.value.length,
                itemBuilder: (BuildContext context, int index) {
                  return tileData.value[index];
                },
              );
            }),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    _initTileData(context);
    return AppBarView(
        title: title, isAppBar: false, child: _buildRefreshStockView(context));
  }
}
