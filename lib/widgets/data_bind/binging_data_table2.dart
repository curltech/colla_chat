import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

class BindingDataTable2<T> extends StatelessWidget {
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
  final Function(int, bool?)? onSelectChanged;
  final Function(int index)? onLongPress;

  BindingDataTable2({
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

  double totalWidth = 0.0;

  /// 过滤条件的多项选择框的列定义
  List<DataColumn2> _buildDataColumns() {
    totalWidth = 0.0;
    List<DataColumn2> dataColumns = [];
    for (var platformDataColumn in platformDataColumns) {
      totalWidth = platformDataColumn.width + totalWidth;
      InputType inputType = platformDataColumn.inputType;
      if (inputType == InputType.custom) {
        dataColumns.add(
          DataColumn2(
            label: CommonAutoSizeText(
                AppLocalizations.t(platformDataColumn.label)),
            fixedWidth: platformDataColumn.width,
          ),
        );
      } else {
        dataColumns.add(
          DataColumn2(
              label: CommonAutoSizeText(
                  AppLocalizations.t(platformDataColumn.label)),
              fixedWidth: platformDataColumn.width,
              tooltip: platformDataColumn.hintText,
              numeric: platformDataColumn.dataType == DataType.percentage ||
                  platformDataColumn.dataType == DataType.double ||
                  platformDataColumn.dataType == DataType.int ||
                  platformDataColumn.dataType == DataType.num,
              onSort: platformDataColumn.onSort),
        );
      }
    }
    totalWidth = 300 + totalWidth;
    return dataColumns;
  }

  DataRow2 _getRow(int index) {
    List<dynamic> data = controller.data;
    dynamic t = data[index];
    var tMap = JsonUtil.toJson(t);
    List<DataCell> cells = [];
    for (PlatformDataColumn platformDataColumn in platformDataColumns) {
      InputType inputType = platformDataColumn.inputType;
      if (inputType == InputType.custom &&
          platformDataColumn.buildSuffix != null) {
        Widget suffix = platformDataColumn.buildSuffix!(index, t);
        var dataCell = DataCell(suffix);
        cells.add(dataCell);
      } else {
        DataType dataType = platformDataColumn.dataType;
        String name = platformDataColumn.name;
        dynamic fieldValue = tMap[name];
        Color? textColor;
        Color? textBackgroundColor;
        if (fieldValue != null) {
          if (fieldValue is num) {
            if (fieldValue > 0 && platformDataColumn.positiveColor != null) {
              textBackgroundColor = platformDataColumn.positiveColor;
              textColor = Colors.white;
            }
            if (fieldValue < 0 && platformDataColumn.negativeColor != null) {
              textBackgroundColor = platformDataColumn.negativeColor;
              textColor = Colors.white;
            }
          }
          if (dataType == DataType.percentage) {
            if (fieldValue is num) {
              fieldValue =
                  NumberUtil.stdPercentage(fieldValue.toDouble());
            } else {
              fieldValue = fieldValue.toString();
            }
          } else if (dataType == DataType.double) {
            fieldValue = NumberUtil.stdDouble(fieldValue);
          } else {
            fieldValue = fieldValue.toString();
          }
        } else {
          fieldValue = '';
        }
        TextAlign align = platformDataColumn.align;
        var dataCell = DataCell(
          CommonAutoSizeText(fieldValue!,
              style: TextStyle(
                  backgroundColor: textBackgroundColor, color: textColor),
              textAlign: align),
        );
        cells.add(dataCell);
      }
    }
    bool? checked = EntityUtil.getChecked(t);
    checked ??= false;
    var dataRow = DataRow2.byIndex(
      index: index,
      selected: checked,
      onSelectChanged: (value) {
        bool? checked = EntityUtil.getChecked(t);
        var fn = onSelectChanged;
        if (fn != null) {
          fn(index, value);
        } else if (checked != value) {
          EntityUtil.setChecked(t, value);
        }
      },
      onTap: () {
        controller.currentIndex = index;
        var fn = onTap;
        if (fn != null) {
          fn(index);
        }
      },
      onDoubleTap: () {
        controller.currentIndex = index;
        var fn = onDoubleTap;
        if (fn != null) {
          fn(index);
        }
      },
      onLongPress: () {
        var fn = onLongPress;
        if (fn != null) {
          fn(index);
        }
      },
      cells: cells,
    );

    return dataRow;
  }

  /// 过滤条件的多项选择框的行数据
  List<DataRow2> _buildDataRows() {
    int length = controller.length;
    List<DataRow2> rows = [];
    for (int index = 0; index < length; ++index) {
      DataRow2 dataRow = _getRow(index);
      rows.add(dataRow);
    }
    return rows;
  }

  /// 过滤条件的多项选择框的表
  Widget _buildDataTable(BuildContext context) {
    return Obx(() {
      return DataTable2(
        key: UniqueKey(),
        dataRowHeight: dataRowHeight,
        minWidth: minWidth ?? 2000,
        dividerThickness: 0.0,
        showCheckboxColumn: showCheckboxColumn,
        horizontalMargin: horizontalMargin,
        columnSpacing: columnSpacing,
        fixedLeftColumns: fixedLeftColumns,
        sortArrowIcon: Icons.keyboard_arrow_up,
        headingCheckboxTheme: CheckboxThemeData(
          side: BorderSide(color: myself.primary),
          fillColor: WidgetStateColor.resolveWith((states) => myself.primary),
          // checkColor: MaterialStateColor.resolveWith((states) => Colors.white)
        ),
        datarowCheckboxTheme: CheckboxThemeData(
          side: BorderSide(color: myself.primary),
          fillColor: WidgetStateColor.resolveWith((states) => myself.primary),
          // checkColor: MaterialStateColor.resolveWith((states) => Colors.white)
        ),
        sortColumnIndex: controller.sortColumnIndex.value,
        sortAscending: controller.sortAscending.value,
        columns: _buildDataColumns(),
        rows: _buildDataRows(),
        onSelectAll: (val) {
          if (val != null) {
            List<dynamic> data = controller.data;
            for (dynamic t in data) {
              EntityUtil.setChecked(t, val);
            }
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = _buildDataTable(context);

    return dataTableView;
  }
}
