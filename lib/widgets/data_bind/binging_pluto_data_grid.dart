import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pluto_grid/pluto_grid.dart';

class BindingPlutoDataGrid<T> extends StatelessWidget {
  final List<PlatformDataColumn> platformDataColumns;
  final DataListController<T> controller;
  final bool showCheckboxColumn;
  final double? dataRowHeight;
  final double? minWidth;
  final double? horizontalMargin;
  final double? columnSpacing;
  final int fixedLeftColumns;
  final Function(int index)? onTap;
  final Function(int index)? onDoubleTap;
  final Function(bool?)? onSelectChanged;
  final Function(int index)? onLongPress;

  const BindingPlutoDataGrid({
    super.key,
    required this.platformDataColumns,
    this.onTap,
    this.onSelectChanged,
    this.onLongPress,
    required this.controller,
    this.onDoubleTap,
    this.showCheckboxColumn = true,
    this.dataRowHeight,
    this.minWidth,
    this.horizontalMargin,
    this.columnSpacing,
    this.fixedLeftColumns = 0,
  });

  /// 过滤条件的多项选择框的列定义
  List<PlutoColumn> _buildDataColumns() {
    List<PlutoColumn> dataColumns = [];
    for (var platformDataColumn in platformDataColumns) {
      PlutoColumnType type = PlutoColumnType.text();
      DataType dataType = platformDataColumn.dataType;
      if (dataType == DataType.double ||
          dataType == DataType.int ||
          dataType == DataType.num) {
        type = PlutoColumnType.number();
      } else if (dataType == DataType.datetime) {
        type = PlutoColumnType.date();
      } else if (dataType == DataType.time) {
        type = PlutoColumnType.time();
      } else if (dataType == DataType.list) {
        type = PlutoColumnType.select([]);
      }
      InputType inputType = platformDataColumn.inputType;
      if (inputType == InputType.custom) {
        dataColumns.add(PlutoColumn(
          title: AppLocalizations.t(platformDataColumn.label),
          field: platformDataColumn.name,
          type: type,
        ));
      } else {
        dataColumns.add(
          PlutoColumn(
              title: AppLocalizations.t(platformDataColumn.label),
              field: platformDataColumn.name,
              type: type,
              sort: PlutoColumnSort.ascending),
        );
      }
    }
    return dataColumns;
  }

  /// 过滤条件的多项选择框的行数据
  List<PlutoRow> _buildDataRows() {
    List data = controller.data;
    List<PlutoRow> rows = [];
    for (int index = 0; index < data.length; ++index) {
      dynamic t = data[index];
      var tMap = JsonUtil.toJson(t);
      Map<String, PlutoCell> cells = {};
      for (PlatformDataColumn platformDataColumn in platformDataColumns) {
        String name = platformDataColumn.name;
        InputType inputType = platformDataColumn.inputType;
        if (inputType == InputType.custom &&
            platformDataColumn.buildSuffix != null) {
          Widget suffix = platformDataColumn.buildSuffix!(index, t);
          var dataCell = PlutoCell(value: suffix);
          cells[name] = dataCell;
        } else {
          dynamic fieldValue = tMap[name];
          if (fieldValue != null) {
            if (fieldValue is double) {
              fieldValue = NumberUtil.stdDouble(fieldValue);
            } else {
              fieldValue = fieldValue.toString();
            }
          } else {
            fieldValue = '';
          }

          var dataCell = PlutoCell(value: fieldValue!);
          cells[name] = dataCell;
        }
      }
      bool? selected = EntityUtil.getSelected(t);
      selected ??= false;
      var dataRow = PlutoRow(
        type: PlutoRowType.normal(),
        checked: selected,
        cells: cells,
      );
      rows.add(dataRow);
    }
    return rows;
  }

  /// 过滤条件的多项选择框的表
  Widget _buildDataTable(BuildContext context) {
    return Obx(() {
      return PlutoGrid(
        key: UniqueKey(),
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
        columns: _buildDataColumns(),
        rows: _buildDataRows(),
        onLoaded: (PlutoGridOnLoadedEvent event) {},
        onChanged: (PlutoGridOnChangedEvent event) {},
        onSelected: (PlutoGridOnSelectedEvent event) {},
        onRowChecked: (PlutoGridOnRowCheckedEvent event) {},
        onRowDoubleTap: (PlutoGridOnRowDoubleTapEvent event) {},
        onRowSecondaryTap: (PlutoGridOnRowSecondaryTapEvent event) {},
        onRowsMoved: (PlutoGridOnRowsMovedEvent event) {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = _buildDataTable(context);

    return dataTableView;
  }
}
