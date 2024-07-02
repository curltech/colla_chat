import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/service/stock/stock_line.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 运行后台批处理，更新数据
class UpdateStockWidget extends StatefulWidget with TileDataMixin {
  UpdateStockWidget({super.key});

  @override
  State<StatefulWidget> createState() => _UpdateStockWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'update_stock';

  @override
  IconData get iconData => Icons.update;

  @override
  String get title => 'UpdateStock';
}

class _UpdateStockWidgetState extends State<UpdateStockWidget>
    with TickerProviderStateMixin {
  final TextEditingController _startDateTextController =
      TextEditingController();
  final TextEditingController _tsCodeTextController = TextEditingController();
  List<TileData> tileData = [];

  @override
  initState() {
    _initTileData();
    super.initState();
  }

  _initTileData() {
    tileData.addAll([
      TileData(
          title: '预测',
          subtitle: '获取预测数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService.getUpdateForecast(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '快报',
          subtitle: '获取快报数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService.getUpdateExpress(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '业绩',
          subtitle: '获取业绩数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService.getUpdatePerformance(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '日线',
          subtitle: '获取日线数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService.getUpdateDayLine(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '今天日线',
          subtitle: '获取今天的日线数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService.getUpdateTodayLine(_tsCodeTextController.text,
                  int.parse(_startDateTextController.text));
            }
          }),
      TileData(
          title: '分钟线',
          subtitle: '获取分钟线数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService.getUpdateMinLine(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '单只股票今天分钟线',
          subtitle: '获取今天的分钟线数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService
                  .getUpdateTodayMinLine(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '周月季年线',
          subtitle: '获取周月季年线数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService.getUpdateWmqyLine(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '单只季度业绩汇总',
          subtitle: '汇总单只股票的季度业绩数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService
                  .getUpdateWmqyQPerformance(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '单只季度业绩最新价汇总',
          subtitle: '汇总单只股票的季度业绩最新价数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService
                  .getUpdateDayQPerformance(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '单只季度业绩统计汇总',
          subtitle: '汇总单只股票的季度业绩统计数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService.getUpdateQStat(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '单只季度业绩评分汇总',
          subtitle: '汇总单只股票的季度业绩评分数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService.getUpdateStatScore(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '单只日线统计',
          subtitle: '计算单只股票的日线统计数据',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty &&
                _startDateTextController.text.isNotEmpty) {
              stockLineService.updateStat(_tsCodeTextController.text,
                  int.parse(_startDateTextController.text));
            }
          }),
      TileData(
          title: '单只过去1,3,5日线均线',
          subtitle: '计算单只股票的过去1,3,5日线均线',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty &&
                _startDateTextController.text.isNotEmpty) {
              stockLineService.updateBeforeMa(_tsCodeTextController.text,
                  int.parse(_startDateTextController.text));
            }
          }),
      TileData(
          title: '计算单只股票的买卖点事件',
          subtitle: '计算单只股票的买卖点事件',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty) {
              stockLineService.getUpdateEventCond(_tsCodeTextController.text);
            }
          }),
      TileData(
          title: '创建模型数据文件',
          subtitle: '创建模型数据文件',
          onTap: (int index, String title, {String? subtitle}) async {
            bool? confirm =
                await DialogUtil.confirm(context, content: subtitle!);
            if (confirm == null || !confirm) {
              return;
            }
            if (_tsCodeTextController.text.isNotEmpty &&
                _startDateTextController.text.isNotEmpty) {
              stockLineService.writeFile(_tsCodeTextController.text,
                  int.parse(_startDateTextController.text));
            }
          }),
    ]);
  }

  Widget _buildUpdateStockView(BuildContext context) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
          child: CommonAutoSizeTextFormField(
              controller: _tsCodeTextController,
              keyboardType: TextInputType.text,
              labelText: AppLocalizations.t('tsCode'))),
      Container(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
          child: CommonAutoSizeTextFormField(
              controller: _startDateTextController,
              keyboardType: TextInputType.number,
              labelText: AppLocalizations.t('startDate'))),
      Expanded(
          child: DataListView(
        itemCount: tileData.length,
        itemBuilder: (BuildContext context, int index) {
          return tileData[index];
        },
      )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: widget.title,
        withLeading: true,
        child: _buildUpdateStockView(context));
  }
}
