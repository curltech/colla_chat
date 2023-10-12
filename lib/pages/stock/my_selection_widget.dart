import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/add_share_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

final List<PlutoColumn> shareColumns = [
  PlutoColumn(
    title: '代码/名',
    field: 'ts_code/name',
    type: PlutoColumnType.text(),
  ),
  PlutoColumn(
    title: '细分行业',
    field: 'industry',
    type: PlutoColumnType.text(),
    textAlign: PlutoColumnTextAlign.start,
  ),
  PlutoColumn(
    title: '日期/来源',
    field: 'trade_date/source',
    type: PlutoColumnType.text(),
    textAlign: PlutoColumnTextAlign.start,
  ),
  PlutoColumn(
    title: '价/涨幅',
    field: 'close/pct_chg_close',
    type: PlutoColumnType.text(),
    textAlign: PlutoColumnTextAlign.end,
  ),
  PlutoColumn(
    title: '量变化/换手率',
    field: 'pct_chg_vol/turnover',
    type: PlutoColumnType.text(),
    textAlign: PlutoColumnTextAlign.end,
  ),
  PlutoColumn(
    title: 'pe/peg',
    field: 'pe/peg',
    type: PlutoColumnType.text(),
    textAlign: PlutoColumnTextAlign.end,
  ),
  PlutoColumn(
    title: 'pe/peg位置',
    field: 'percent_pe/percent_peg',
    type: PlutoColumnType.text(),
    textAlign: PlutoColumnTextAlign.end,
  ),
  PlutoColumn(
    title: 'industry pe/peg位置',
    field: 'industry_percent_pe/industry_percent_peg',
    type: PlutoColumnType.text(),
    textAlign: PlutoColumnTextAlign.end,
  ),
  PlutoColumn(
    title: '13close/34close位置',
    field: 'percent13_close/percent34_close',
    type: PlutoColumnType.text(),
    textAlign: PlutoColumnTextAlign.end,
  ),
];

/// 自选股的控制器
final DataListController<dynamic> shareController =
    DataListController<dynamic>();

///自选股和分组的查询界面
class ShareSelectionWidget extends StatefulWidget with TileDataMixin {
  final AddShareWidget addShareWidget = AddShareWidget();

  ShareSelectionWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(addShareWidget);
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
  final ValueNotifier<List<PlutoRow>> _sharePlutoRows =
      ValueNotifier<List<PlutoRow>>([]);

  @override
  initState() {
    super.initState();
    shareController.addListener(_updateShare);
    shareService.findMine().then((List<dynamic> value) {
      shareController.replaceAll(value);
    });
  }

  _updateShare() {
    _buildSharePlutoRows();
  }

  _buildSharePlutoRows() {
    List<PlutoRow> rows = [];
    var data = shareController.data;
    for (int index = 0; index < data.length; ++index) {
      var d = data[index];
      var dataMap = JsonUtil.toJson(d);
      Map<String, PlutoCell> cells = {};
      for (PlutoColumn shareColumn in shareColumns) {
        List<String> fields = shareColumn.field.split('/');
        String? value;
        for (int j = 0; j < fields.length; ++j) {
          String field = fields[j];
          dynamic fieldValue = dataMap[field];
          fieldValue ??= '';
          if (value == null) {
            value = fieldValue.toString();
          } else {
            value = '$value\n$fieldValue';
          }
        }

        var dataCell = PlutoCell(value: value);
        cells[shareColumn.field] = dataCell;
      }
      var dataRow = PlutoRow(
        cells: cells,
      );
      rows.add(dataRow);
    }
    _sharePlutoRows.value = rows;
  }

  Widget _buildShareListView(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _sharePlutoRows,
        builder: (context, value, child) {
          return PlutoGrid(
              key: UniqueKey(),
              columns: shareColumns,
              rows: value,
              // rowColorCallback:(PlutoRowColorContext context){
              //   return context.row.cells[''].value;
              // },
              configuration: PlutoGridConfiguration(
                  style: PlutoGridStyleConfig(
                enableColumnBorderVertical: false,
                enableColumnBorderHorizontal: false,
                enableCellBorderVertical: false,
                enableCellBorderHorizontal: false,
                gridBackgroundColor: Colors.white.withOpacity(0.0),
                rowColor: Colors.white.withOpacity(0.0),
                columnTextStyle: const TextStyle(
                  color: Colors.black,
                  decoration: TextDecoration.none,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                cellTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              )));
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
