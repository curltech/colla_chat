import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/add_share_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

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
  final ValueNotifier<List<PlutoColumn>> _sharePlutoColumns =
      ValueNotifier<List<PlutoColumn>>([]);

  @override
  initState() {
    super.initState();
    shareController.addListener(_updateShare);
    shareService.findMine().then((List<dynamic> value) {
      shareController.replaceAll(value);
    });
  }

  _updateShare() {
    _buildRows();
    _buildPlutoColumn();
  }

  _buildPlutoColumn() {
    var data = shareController.data;
    List<PlutoColumn> dataColumns = [];
    if (data.isNotEmpty) {
      Map<String, dynamic> map = data.first;
      for (var entry in map.entries) {
        String key = entry.key;
        dynamic value = entry.value;
        var type = PlutoColumnType.text();
        if (value != null) {
          if (value is int || value is double) {
            type = PlutoColumnType.number();
          } else if (value is DateTime) {
            type = PlutoColumnType.date();
          } else if (value is TimeOfDay) {
            type = PlutoColumnType.time();
          }
        }
        var dataColumn = PlutoColumn(
            title: AppLocalizations.t(key),
            field: key,
            type: type,
            sort: PlutoColumnSort.ascending);
        dataColumns.add(dataColumn);
      }
    }
    _sharePlutoColumns.value = dataColumns;
  }

  List<PlutoRow> _buildRows() {
    List<PlutoRow> rows = [];
    var data = shareController.data;
    for (int index = 0; index < data.length; ++index) {
      var d = data[index];
      var dataMap = JsonUtil.toJson(d);
      Map<String, PlutoCell> cells = {};
      for (var entry in dataMap.entries) {
        String key = entry.key;
        dynamic value = entry.value;
        value = value ?? '';
        var dataCell = PlutoCell(value: value);
        cells[key] = dataCell;
      }
      var dataRow = PlutoRow(
        cells: cells,
      );
      rows.add(dataRow);
    }
    return rows;
  }

  Widget _buildShareListView(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _sharePlutoColumns,
        builder: (context, value, child) {
          return PlutoGrid(
              columns: value,
              rows: _buildRows(),
              onChanged: (PlutoGridOnChangedEvent event) {},
              onSelected: (PlutoGridOnSelectedEvent event) {
                ///进入路由
                ///event.row
              },
              onRowChecked: (PlutoGridOnRowCheckedEvent event) {},
              onRowDoubleTap: (PlutoGridOnRowDoubleTapEvent event) {},
              onRowSecondaryTap: (PlutoGridOnRowSecondaryTapEvent event) {},
              onRowsMoved: (PlutoGridOnRowsMovedEvent event) {},
              createHeader: (PlutoGridStateManager stateManager) {
                //前端分页
                stateManager.setPageSize(10, notify: false);
                //stateManager.setShowLoading(true);
                //stateManager.refRows
                //stateManager.refRows.originalList
                return PlutoPagination(stateManager);
              },
              // createFooter: (PlutoGridStateManager event) {},
              // rowColorCallback: (PlutoRowColorContext event) {},
              configuration: const PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  enableColumnBorderVertical: false,
                  enableColumnBorderHorizontal: false,
                  gridBorderColor: Colors.white,
                  borderColor: Colors.white,
                  activatedBorderColor: Colors.white,
                  inactivatedBorderColor: Colors.white,
                ),
                localeText: PlutoGridLocaleText.china(),
              ),
              mode: PlutoGridMode.normal);
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
