import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trina_grid/trina_grid.dart';

class BindingTrinaDataGrid<T> extends StatelessWidget {
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

  const BindingTrinaDataGrid({
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
  List<TrinaColumn> _buildDataColumns() {
    List<TrinaColumn> dataColumns = [];
    for (var platformDataColumn in platformDataColumns) {
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
      if (dataType == DataType.double || dataType == DataType.num) {
        type = TrinaColumnType.number(format: '#,###.00');
        align = TrinaColumnTextAlign.end;
      } else if (dataType == DataType.int) {
        type = TrinaColumnType.number(format: '#,###');
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
            // enableRowChecked: true,
            // enableTitleChecked: true,
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
              // enableRowChecked: true,
              // enableTitleChecked: true,
              enableSorting: true,
              enableContextMenu: false,
              enableFilterMenuItem: false,
              enableHideColumnMenuItem: false,
              enableSetColumnsMenuItem: false,
              enableAutoEditing: false,
              enableEditingMode: false,
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
      dynamic t = data[index];
      var tMap = JsonUtil.toJson(t);
      Map<String, TrinaCell> cells = {};
      for (PlatformDataColumn platformDataColumn in platformDataColumns) {
        String name = platformDataColumn.name;
        InputType inputType = platformDataColumn.inputType;
        if (inputType == InputType.custom &&
            platformDataColumn.buildSuffix != null) {
          Widget suffix = platformDataColumn.buildSuffix!(index, t);
          var dataCell =
              TrinaCell(renderer: (TrinaCellRendererContext context) {
            return Align(alignment: platformDataColumn.align, child: suffix);
          });
          cells[name] = dataCell;
        } else {
          dynamic fieldValue = tMap[name];
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
      bool? selected = EntityUtil.getSelected(t);
      selected ??= false;
      var dataRow = TrinaRow(
        sortIdx: index,
        type: TrinaRowType.normal(),
        checked: selected,
        cells: cells,
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
        enableCellBorderHorizontal: false,
        oddRowColor: myself.secondary.withAlpha(64),
        evenRowColor: Colors.grey.withAlpha(64),
        gridBorderColor: myself.primary,
      );
    } else {
      trinaGridStyleConfig = TrinaGridStyleConfig(
        enableColumnBorderVertical: true,
        enableColumnBorderHorizontal: true,
        enableCellBorderVertical: false,
        enableCellBorderHorizontal: false,
        oddRowColor: myself.secondary.withAlpha(64),
        evenRowColor: Colors.grey.withAlpha(64),
        gridBorderColor: myself.primary,
      );
    }
    return TrinaGridConfiguration(
      style: trinaGridStyleConfig,
      localeText: localeText,
    );
  }

  /// 过滤条件的多项选择框的表
  Widget _buildDataTable(BuildContext context) {
    return Obx(() {
      return TrinaGrid(
        key: UniqueKey(),
        configuration: _buildTrinaGridConfiguration(context),
        columns: _buildDataColumns(),
        rows: _buildDataRows(),
        onLoaded: (TrinaGridOnLoadedEvent event) {},
        onChanged: (TrinaGridOnChangedEvent event) {},
        onSelected: (TrinaGridOnSelectedEvent event) {
          int? index = event.row?.sortIdx;
          controller.setCurrentIndex = index;
          var fn = onDoubleTap;
          if (fn != null && index != null) {
            fn(index);
          }
        },
        onRowChecked: (TrinaGridOnRowCheckedEvent event) {
          dynamic value = event.row?.data;
          int? index = event.row?.sortIdx;
          bool? selected = event.isChecked;
          var fn = onSelectChanged;
          if (fn != null && index != null) {
            fn(index, selected!);
          } else {
            if (value != null) {
              EntityUtil.setSelected(value, selected);
            }
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
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = _buildDataTable(context);

    return dataTableView;
  }
}
