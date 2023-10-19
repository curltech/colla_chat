import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/stock_line_chart_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/number_format_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

/// 自选股的控制器
final DataListController<dynamic> shareController =
    DataListController<dynamic>();

///自选股和分组的查询界面
class ShareSelectionWidget extends StatefulWidget with TileDataMixin {
  final StockLineChartWidget stockLineChartWidget =
      const StockLineChartWidget();

  ShareSelectionWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(stockLineChartWidget);
  }

  @override
  State<StatefulWidget> createState() => _ShareSelectionWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'my_selection';

  @override
  IconData get iconData => Icons.featured_play_list_outlined;

  @override
  String get title => 'MySelection';
}

class _ShareSelectionWidgetState extends State<ShareSelectionWidget>
    with TickerProviderStateMixin {
  final List<PlatformDataColumn> shareColumns = [
    PlatformDataColumn(
      label: '代码/名',
      name: 'ts_code/name',
    ),
    PlatformDataColumn(
      label: '日期/细分行业',
      name: 'trade_date/industry',
    ),
    PlatformDataColumn(
      label: '价/涨幅',
      name: 'close/pct_chg_close',
      dataType: DataType.double,
      align: MainAxisAlignment.end,
    ),
    PlatformDataColumn(
      label: '量变化/换手率',
      name: 'pct_chg_vol/turnover',
      dataType: DataType.double,
      align: MainAxisAlignment.end,
    ),
    PlatformDataColumn(
      label: 'pe/peg',
      name: 'pe/peg',
      dataType: DataType.double,
      align: MainAxisAlignment.end,
    ),
    PlatformDataColumn(
      label: 'pe/peg位置',
      name: 'percent_pe/percent_peg',
      dataType: DataType.double,
      align: MainAxisAlignment.end,
    ),
    PlatformDataColumn(
      label: 'industry pe/peg位置',
      name: 'industry_percent_pe/industry_percent_peg',
      dataType: DataType.double,
      align: MainAxisAlignment.end,
    ),
    PlatformDataColumn(
      label: '13close/34close位置',
      name: 'percent13_close/percent34_close',
      dataType: DataType.double,
      align: MainAxisAlignment.end,
    ),
  ];

  @override
  initState() {
    shareController.addListener(_updateShare);
    super.initState();
  }

  _updateShare() {
    _buildShareDataRows();
  }

  List<DataColumn2> _buildShareDataColumns() {
    List<DataColumn2> dataColumns = [];
    for (var shareColumn in shareColumns) {
      dataColumns.add(DataColumn2(
          label: Text(shareColumn.label),
          fixedWidth: 130,
          numeric: shareColumn.dataType == DataType.double ||
              shareColumn.dataType == DataType.int));
    }
    return dataColumns;
  }

  Future<List<DataRow2>> _buildShareDataRows() async {
    List<DataRow2> rows = [];
    List<dynamic> data = shareController.data;
    if (data.isEmpty) {
      List<dynamic> value = await remoteShareService.sendFindMine();
      shareController.replaceAll(value);
      data = shareController.data;
    }
    List<String> tsCodes = shareService.subscription.split(',');
    multiStockLineController.replaceAll(tsCodes);
    for (int index = 0; index < data.length; ++index) {
      var d = data[index];
      var dataMap = JsonUtil.toJson(d);
      List<DataCell> cells = [];
      for (PlatformDataColumn shareColumn in shareColumns) {
        List<String> names = shareColumn.name.split('/');
        String? value;
        for (int j = 0; j < names.length; ++j) {
          String name = names[j];
          dynamic fieldValue = dataMap[name];
          if (fieldValue != null) {
            if (fieldValue is double) {
              fieldValue = NumberFormatUtil.stdDouble(fieldValue);
            } else {
              fieldValue = fieldValue.toString();
            }
          } else {
            fieldValue = '';
          }

          if (value == null) {
            value = fieldValue;
          } else {
            value = '$value\n$fieldValue';
          }
        }

        var dataCell = DataCell(Text(value!));
        cells.add(dataCell);
      }
      var dataRow = DataRow2(
        cells: cells,
        onTap: () {
          String? tsCode = dataMap['ts_code'];
          String? name = dataMap['name'];
          name ??= '';
          if (tsCode != null) {
            multiStockLineController.put(tsCode, name);
            indexWidgetProvider.push('stockline_chart');
          }
        },
      );
      rows.add(dataRow);
    }
    return rows;
  }

  Widget _buildShareListView(BuildContext context) {
    return FutureBuilder(
        future: _buildShareDataRows(),
        builder: (BuildContext context, AsyncSnapshot<List<DataRow>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            var value = snapshot.data;
            if (value != null) {
              return DataTable2(
                key: UniqueKey(),
                minWidth: 2000,
                dataRowHeight: 50,
                fixedLeftColumns: 1,
                dividerThickness: 0.0,
                columns: _buildShareDataColumns(),
                rows: value,
              );
            }
          }
          return LoadingUtil.buildLoadingIndicator();
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
    ];
    return AppBarView(
        title: widget.title,
        withLeading: true,
        rightWidgets: rightWidgets,
        child: _buildShareListView(context));
  }

  @override
  void dispose() {
    shareController.removeListener(_updateShare);
    super.dispose();
  }
}
