import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/service/stock/stock_line.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 运行后台批处理，刷新数据
class RefreshStockWidget extends StatefulWidget with TileDataMixin {
  RefreshStockWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RefreshStockWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'refresh_stock';

  @override
  IconData get iconData => Icons.refresh;

  @override
  String get title => 'RefreshStock';
}

class _RefreshStockWidgetState extends State<RefreshStockWidget>
    with TickerProviderStateMixin {
  final TextEditingController _startDateTextController =
      TextEditingController();
  List<TileData> tileData = [];

  @override
  initState() {
    _initTileData();
    super.initState();
  }

  _initTileData() {
    tileData.addAll([
      TileData(
        title: '调度',
        subtitle: '获取数据，汇总，计算评分',
        onTap: (int index, String title, {String? subtitle}) =>
            stockLineService.schedule(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '所有股票今天日线',
        subtitle: '刷新所有股票今天的日线数据',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .refreshTodayLine(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '分钟线',
        subtitle: '刷新所有股票的分钟线数据',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .refreshMinLine(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '所有股票今天分钟线',
        subtitle: '刷新所有股票今天的分钟线数据',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .refreshTodayMinLine(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '季度业绩汇总',
        subtitle: '汇总所有股票的季度业绩数据',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .refreshQPerformance(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '季度业绩统计汇总',
        subtitle: '汇总所有股票的季度业绩统计数据',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .refreshQStat(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '季度业绩评分汇总',
        subtitle: '汇总所有股票的季度业绩评分数据',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .refreshStatScore(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '季度业绩分位评分汇总',
        subtitle: '汇总所有股票的季度业绩分位评分数据',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .createScorePercentile(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '日线统计',
        subtitle: '计算所有股票的日线统计数据',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .refreshStat(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '过去1,3,5日线均线',
        subtitle: '计算所有股票的过去1,3,5日线均线统计数据',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .refreshBeforeMa(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '计算所有股票的买卖点事件',
        subtitle: '计算所有股票的买卖点事件',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .refreshEventCond(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '更新股票信息',
        subtitle: '更新股票信息',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .updateShares(int.parse(_startDateTextController.text)),
      ),
      TileData(
        title: '创建模型数据文件',
        subtitle: '创建模型数据文件',
        onTap: (int index, String title, {String? subtitle}) => stockLineService
            .writeAllFile(int.parse(_startDateTextController.text)),
      ),
    ]);
  }

  Widget _buildRefreshStockView(BuildContext context) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
          child: CommonAutoSizeTextFormField(
            controller: _startDateTextController,
            keyboardType: TextInputType.number,
          )),
      DataListView(tileData: tileData),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: widget.title,
        withLeading: true,
        child: _buildRefreshStockView(context));
  }
}
