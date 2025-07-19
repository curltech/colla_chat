import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/style/platform_style_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trina_grid/trina_grid.dart';

class BindingTrinaDataGrid<T> extends StatelessWidget {
  final List<PlatformDataColumn> platformDataColumns;
  final DataListController<T> controller;
  final bool showCheckboxColumn;
  final double? rowHeight;
  final double? columnHeight;
  final double? minWidth;
  final double? horizontalMargin;
  final double? columnSpacing;
  final int fixedLeftColumns;
  final Function(int index)? onDoubleTap;
  final Function(int index, List<dynamic> data)? onSelected;
  final Function(int, bool?)? onRowChecked;
  final Function(int, dynamic)? onChanged;
  final Function(int, dynamic)? onLongPress;

  const BindingTrinaDataGrid({
    super.key,
    required this.platformDataColumns,
    this.onSelected,
    this.onChanged,
    this.onLongPress,
    this.onRowChecked,
    required this.controller,
    this.onDoubleTap,
    this.showCheckboxColumn = true,
    this.rowHeight,
    this.columnHeight,
    this.minWidth,
    this.horizontalMargin,
    this.columnSpacing,
    this.fixedLeftColumns = 0,
  });

  /// 过滤条件的多项选择框的列定义
  List<TrinaColumn> _buildDataColumns() {
    List<TrinaColumn> dataColumns = [];
    for (int i = 0; i < platformDataColumns.length; ++i) {
      PlatformDataColumn platformDataColumn = platformDataColumns[i];
      TrinaColumnType type = TrinaColumnType.text();
      TrinaColumnTextAlign align = TrinaColumnTextAlign.start;
      if (platformDataColumn.align == Alignment.center) {
        align = TrinaColumnTextAlign.center;
      } else if (platformDataColumn.align == Alignment.centerRight) {
        align = TrinaColumnTextAlign.right;
      } else if (platformDataColumn.align == Alignment.centerLeft) {
        align = TrinaColumnTextAlign.left;
      }
      DataType dataType = platformDataColumn.dataType;
      if (dataType == DataType.int) {
        type = TrinaColumnType.number(
            format: platformDataColumn.format ?? '#,###');
        align = TrinaColumnTextAlign.end;
      } else if (dataType == DataType.double || dataType == DataType.num) {
        type = TrinaColumnType.number(
            format: platformDataColumn.format ?? '#,###.00');
        align = TrinaColumnTextAlign.end;
      } else if (dataType == DataType.percentage) {
        type = TrinaColumnType.percentage();
        align = TrinaColumnTextAlign.end;
      } else if (dataType == DataType.datetime) {
        type = TrinaColumnType.date();
        align = TrinaColumnTextAlign.end;
      } else if (dataType == DataType.time) {
        type = TrinaColumnType.time();
        align = TrinaColumnTextAlign.end;
      } else if (dataType == DataType.list) {
        type = TrinaColumnType.select([]);
      }
      InputType inputType = platformDataColumn.inputType;
      if (inputType == InputType.custom) {
        dataColumns.add(TrinaColumn(
            title: AppLocalizations.t(platformDataColumn.label),
            field: platformDataColumn.name,
            textAlign: align,
            width: platformDataColumn.width ?? TrinaGridSettings.columnWidth,
            type: type,
            enableRowChecked: i == 0 ? showCheckboxColumn : false,
            backgroundColor: Colors.grey.withAlpha(0),
            enableSorting: false,
            enableContextMenu: false,
            enableFilterMenuItem: false,
            enableHideColumnMenuItem: false,
            enableSetColumnsMenuItem: false,
            enableAutoEditing: false,
            enableEditingMode: false,
            sort: TrinaColumnSort.none));
      } else {
        dataColumns.add(
          TrinaColumn(
              title: AppLocalizations.t(platformDataColumn.label),
              field: platformDataColumn.name,
              type: type,
              width: platformDataColumn.width ?? TrinaGridSettings.columnWidth,
              enableRowChecked: i == 0 ? true : false,
              backgroundColor: Colors.grey.withAlpha(0),
              enableSorting: platformDataColumn.sort,
              enableContextMenu: platformDataColumn.menu,
              enableFilterMenuItem: platformDataColumn.filter,
              enableHideColumnMenuItem: true,
              enableSetColumnsMenuItem: true,
              enableAutoEditing: false,
              enableEditingMode: !platformDataColumn.readOnly,
              sort: TrinaColumnSort.ascending),
        );
      }
    }
    return dataColumns;
  }

  /// 过滤条件的多项选择框的行数据
  List<TrinaRow> _buildDataRows() {
    List data = controller.data;
    List<TrinaRow> rows = [];
    for (int index = 0; index < data.length; ++index) {
      dynamic d = data[index];
      var dMap = JsonUtil.toJson(d);
      Map<String, TrinaCell> cells = {};
      for (PlatformDataColumn platformDataColumn in platformDataColumns) {
        String name = platformDataColumn.name;
        InputType inputType = platformDataColumn.inputType;
        if (inputType == InputType.custom &&
            platformDataColumn.buildSuffix != null) {
          Widget suffix = platformDataColumn.buildSuffix!(index, d);
          var dataCell =
              TrinaCell(renderer: (TrinaCellRendererContext context) {
            return Align(alignment: platformDataColumn.align, child: suffix);
          });
          cells[name] = dataCell;
        } else {
          dynamic fieldValue = dMap[name];
          TrinaCell dataCell = TrinaCell(value: fieldValue ?? '');
          if (platformDataColumn.positiveColor != null ||
              platformDataColumn.negativeColor != null) {
            String value = '';
            Color? color;
            DataType dataType = platformDataColumn.dataType;
            if (dataType == DataType.double ||
                dataType == DataType.num ||
                dataType == DataType.int ||
                dataType == DataType.percentage) {
              if (fieldValue != null) {
                if (dataType == DataType.double) {
                  value = NumberUtil.stdDouble(fieldValue);
                } else if (dataType == DataType.percentage) {
                  value = NumberUtil.stdPercentage(fieldValue);
                } else {
                  value = fieldValue!.toString();
                }
                if (fieldValue > 0) {
                  color = platformDataColumn.positiveColor;
                } else if (fieldValue < 0) {
                  color = platformDataColumn.negativeColor;
                }
              } else {
                fieldValue = '';
              }
              if (color != null) {
                dataCell = TrinaCell(
                    value: fieldValue!,
                    renderer: (rendererContext) {
                      return Text(
                        value,
                        style: TextStyle(color: color),
                      );
                    });
              }
            }
          }
          cells[name] = dataCell;
        }
      }
      bool? selected = EntityUtil.getSelected(d);
      selected ??= false;
      var dataRow = TrinaRow(
        sortIdx: index,
        type: TrinaRowType.normal(),
        checked: selected,
        cells: cells,
        data: d,
      );
      rows.add(dataRow);
    }
    return rows;
  }

  TrinaGridConfiguration _buildTrinaGridConfiguration(BuildContext context) {
    Brightness brightness = myself.getBrightness(context);
    Locale? locale = AppLocalizations.current?.locale;
    TrinaGridLocaleText localeText;
    if (locale == Locale('zh', 'TW') || locale == Locale('zh', 'CN')) {
      localeText = TrinaGridLocaleText.china();
    } else if (locale == Locale('ja', 'JP')) {
      localeText = TrinaGridLocaleText.japanese();
    } else if (locale == Locale('ko', 'KR')) {
      localeText = TrinaGridLocaleText.korean();
    } else {
      localeText = TrinaGridLocaleText();
    }
    TrinaGridStyleConfig trinaGridStyleConfig;
    if (brightness == Brightness.dark) {
      trinaGridStyleConfig = TrinaGridStyleConfig.dark(
        enableColumnBorderVertical: true,
        enableColumnBorderHorizontal: true,
        enableCellBorderVertical: false,
        enableCellBorderHorizontal: true,
        rowHeight: rowHeight ?? TrinaGridSettings.rowHeight,
        columnHeight: columnHeight ?? TrinaGridSettings.rowHeight,
        oddRowColor: myself.primaryColor.withAlpha(32),
        evenRowColor: Colors.grey.withAlpha(32),
        gridBackgroundColor: Colors.white.withAlpha(0),
        rowColor: Colors.white.withAlpha(0),
        activatedColor: Colors.blueGrey,
        gridBorderColor: Colors.white.withAlpha(0),
        borderColor: Colors.white.withAlpha(0),
        activatedBorderColor: myself.primaryColor,
        inactivatedBorderColor: Colors.white.withAlpha(0),
        filterHeaderIconColor: myself.primaryColor,
      );
    } else {
      trinaGridStyleConfig = TrinaGridStyleConfig(
        enableColumnBorderVertical: true,
        enableColumnBorderHorizontal: false,
        enableCellBorderVertical: false,
        enableCellBorderHorizontal: true,
        rowHeight: rowHeight ?? TrinaGridSettings.rowHeight,
        columnHeight: columnHeight ?? TrinaGridSettings.rowHeight,
        oddRowColor: myself.primaryColor.withAlpha(32),
        evenRowColor: Colors.grey.withAlpha(32),
        gridBackgroundColor: Colors.white.withAlpha(0),
        rowColor: Colors.white.withAlpha(0),
        activatedColor: Colors.blueGrey,
        gridBorderColor: Colors.white.withAlpha(0),
        borderColor: Colors.white.withAlpha(0),
        activatedBorderColor: myself.primaryColor,
        inactivatedBorderColor: Colors.white.withAlpha(0),
        filterHeaderIconColor: myself.primaryColor,
      );
    }
    return TrinaGridConfiguration(
      style: trinaGridStyleConfig,
      localeText: localeText,
      columnSize: TrinaGridColumnSizeConfig(
        autoSizeMode: TrinaAutoSizeMode.scale,
        resizeMode: TrinaResizeMode.normal,
      ),
    );
  }

  /// 过滤条件的多项选择框的表
  Widget _buildDataTable(BuildContext context) {
    return Obx(() {
      List<TrinaRow<dynamic>> rows=_buildDataRows();
      return TrinaGrid(
        key: UniqueKey(),
        mode: TrinaGridMode.normal,
        configuration: _buildTrinaGridConfiguration(context),
        columns: _buildDataColumns(),
        rows: rows,
        onLoaded: (TrinaGridOnLoadedEvent event) {},
        onChanged: (TrinaGridOnChangedEvent event) {
          dynamic value = event.row.data;
          int? index = event.row.sortIdx;
          var fn = onChanged;
          if (fn != null) {
            fn(index, value);
          }
        },
        rowWrapper: (context, row, stateManager) {
          return InkWell(
            onLongPress: () {
              dynamic value = stateManager.currentRow?.data;
              int? index = stateManager.currentRow?.sortIdx;
              var fn = onLongPress;
              if (fn != null && index != null) {
                fn(index, value);
              }
            },
            child: row,
          );
        },
        onSelected: (TrinaGridOnSelectedEvent event) {
          List<dynamic> data = [];
          List<TrinaRow<dynamic>>? selectedRows = event.selectedRows;
          if (selectedRows != null && selectedRows.isNotEmpty) {
            for (var row in selectedRows) {
              dynamic d = row.data;
              if (d != null) {
                data.add(d);
              }
            }
          } else {
            dynamic d = event.row?.data;
            if (d != null) {
              data.add(d);
            }
          }
          int? index = event.row?.sortIdx;
          controller.setCurrentIndex = index;
          var fn = onSelected;
          if (fn != null && index != null) {
            fn(index, data);
          }
        },
        onRowChecked: (TrinaGridOnRowCheckedEvent event) {
          dynamic value = event.row?.data;
          int? index = event.row?.sortIdx;
          bool? isChecked = event.isChecked;
          if (value != null) {
            EntityUtil.setSelected(value, isChecked);
          } else {
            for (var value in controller.data) {
              EntityUtil.setSelected(value, isChecked);
            }
          }
          var fn = onRowChecked;
          if (fn != null && index != null) {
            fn(index, isChecked!);
          }
        },
        onRowDoubleTap: (TrinaGridOnRowDoubleTapEvent event) {
          int index = event.row.sortIdx;
          controller.setCurrentIndex = index;
          var fn = onDoubleTap;
          if (fn != null) {
            fn(index);
          }
        },
        onRowSecondaryTap: (TrinaGridOnRowSecondaryTapEvent event) {},
        onRowsMoved: (TrinaGridOnRowsMovedEvent event) {},
        columnMenuDelegate: TrinaColumnMenuDelegateDefault(),
      ).asStyle();
    });
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = _buildDataTable(context);

    return dataTableView;
  }
}
