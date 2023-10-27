import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/number_format_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

class BindingPaginatedDataTable2<T> extends StatefulWidget {
  final List<PlatformDataColumn> platformDataColumns;
  final DataListController<T> controller;
  final bool showCheckboxColumn;
  final double dataRowHeight;
  final double? minWidth;
  final double horizontalMargin;
  final double columnSpacing;
  final int fixedLeftColumns;
  final Function(int index)? onTap;
  final Function(int index)? onDoubleTap;
  final Function(int, bool?)? onSelectChanged;
  final Function(int index)? onLongPress;

  const BindingPaginatedDataTable2({
    Key? key,
    required this.platformDataColumns,
    this.onTap,
    this.onSelectChanged,
    this.onLongPress,
    required this.controller,
    this.onDoubleTap,
    this.showCheckboxColumn = true,
    this.dataRowHeight = kMinInteractiveDimension,
    this.minWidth,
    this.horizontalMargin = 24.0,
    this.columnSpacing = 56.0,
    this.fixedLeftColumns = 0,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BindingPaginatedDataTable2State<T>();
  }
}

class _BindingPaginatedDataTable2State<T>
    extends State<BindingPaginatedDataTable2> {
  double totalWidth = 0.0;
  int _rowsPerPage = 10;
  PaginatorController? paginatorController; // = PaginatorController();

  @override
  initState() {
    widget.controller.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  /// 过滤条件的多项选择框的列定义
  List<DataColumn2> _buildDataColumns() {
    totalWidth = 0.0;
    List<DataColumn2> dataColumns = [];
    for (var platformDataColumn in widget.platformDataColumns) {
      totalWidth += platformDataColumn.width;
      InputType inputType = platformDataColumn.inputType;
      if (inputType == InputType.custom) {
        dataColumns.add(DataColumn2(
            label: CommonAutoSizeText(
                AppLocalizations.t(platformDataColumn.label))));
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
    totalWidth += 300;
    return dataColumns;
  }

  /// 过滤条件的多项选择框的表
  Widget _buildDataTable(BuildContext context) {
    return PaginatedDataTable2(
      key: UniqueKey(),
      availableRowsPerPage: const [2, 5, 10, 30, 100],
      checkboxHorizontalMargin: 12,
      wrapInCard: false,
      renderEmptyRowsInTheEnd: false,
      rowsPerPage: _rowsPerPage,
      autoRowsToHeight: true,
      dividerThickness: 0.0,
      initialFirstRowIndex: 0,
      hidePaginator: false,
      fit: FlexFit.tight,
      dataRowHeight: widget.dataRowHeight,
      minWidth: widget.minWidth ?? 2000,
      showCheckboxColumn: widget.showCheckboxColumn,
      horizontalMargin: widget.horizontalMargin,
      columnSpacing: widget.columnSpacing,
      fixedLeftColumns: widget.fixedLeftColumns,
      sortArrowIcon: Icons.keyboard_arrow_up,
      headingCheckboxTheme: CheckboxThemeData(
        side: BorderSide(color: myself.primary),
        fillColor: MaterialStateColor.resolveWith((states) => myself.primary),
        // checkColor: MaterialStateColor.resolveWith((states) => Colors.white)
      ),
      datarowCheckboxTheme: CheckboxThemeData(
        side: BorderSide(color: myself.primary),
        fillColor: MaterialStateColor.resolveWith((states) => myself.primary),
        // checkColor: MaterialStateColor.resolveWith((states) => Colors.white)
      ),
      sortColumnIndex: widget.controller.sortColumnIndex,
      sortAscending: widget.controller.sortAscending,
      sortArrowAnimationDuration: const Duration(milliseconds: 0),
      columns: _buildDataColumns(),
      onRowsPerPageChanged: (value) {
        _rowsPerPage = value!;
      },
      onPageChanged: (rowIndex) {
        rowIndex / _rowsPerPage;
      },
      controller: paginatorController,
      onSelectAll: (val) {
        if (val != null) {
          setState(() {
            List<dynamic> data = widget.controller.data;
            for (dynamic t in data) {
              EntityUtil.setChecked(t, val);
            }
          });
        }
      },
      source: BindingPaginatedDataSource(
          widget.controller,
          widget.platformDataColumns,
          widget.onTap,
          widget.onDoubleTap,
          widget.onSelectChanged,
          widget.onLongPress),
    );
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = _buildDataTable(context);

    return dataTableView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}

/// 数据源，获取行，行数
class BindingPaginatedDataSource extends DataTableSource {
  final DataListController<dynamic> controller;
  final List<PlatformDataColumn> platformDataColumns;
  final Function(int index)? onTap;
  final Function(int index)? onDoubleTap;
  final Function(int, bool?)? onSelectChanged;
  final Function(int index)? onLongPress;

  BindingPaginatedDataSource(this.controller, this.platformDataColumns,
      this.onTap, this.onDoubleTap, this.onSelectChanged, this.onLongPress);

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
                  NumberFormatUtil.stdPercentage(fieldValue.toDouble());
            } else {
              fieldValue = fieldValue.toString();
            }
          } else if (dataType == DataType.double) {
            fieldValue = NumberFormatUtil.stdDouble(fieldValue);
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
    int length = controller.data.length;
    List<DataRow2> rows = [];
    for (int index = 0; index < length; ++index) {
      DataRow2 dataRow = _getRow(index);
      rows.add(dataRow);
    }
    return rows;
  }

  @override
  DataRow? getRow(int index) {
    return _getRow(index);
  }

  @override
  bool get isRowCountApproximate {
    return false;
  }

  @override
  int get rowCount {
    return 0;
  }

  @override
  int get selectedRowCount {
    return controller.checked.length;
  }
}

/// 显示页号组件
class PageNumber extends StatefulWidget {
  const PageNumber({
    super.key,
    required PaginatorController controller,
  }) : _controller = controller;

  final PaginatorController _controller;

  @override
  PageNumberState createState() => PageNumberState();
}

class PageNumberState extends State<PageNumber> {
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget._controller.addListener(update);
  }

  @override
  void dispose() {
    widget._controller.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(widget._controller.isAttached
        ? 'Page: ${1 + ((widget._controller.currentRowIndex + 1) / widget._controller.rowsPerPage).floor()} of '
            '${(widget._controller.rowCount / widget._controller.rowsPerPage).ceil()}'
        : 'Page: x of y');
  }
}

/// 分页器组件
class BindingPager extends StatefulWidget {
  const BindingPager(this.controller, {super.key});

  final PaginatorController controller;

  @override
  BindingPagerState createState() => BindingPagerState();
}

class BindingPagerState extends State<BindingPager> {
  static const List<int> _availableSizes = [3, 5, 10, 20];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isAttached) return const SizedBox();
    return Container(
      width: 220,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 4,
            offset: const Offset(4, 8), // Shadow position
          ),
        ],
      ),
      child: Theme(
          data: Theme.of(context).copyWith(
              iconTheme: const IconThemeData(color: Colors.white),
              textTheme:
                  const TextTheme(titleMedium: TextStyle(color: Colors.white))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () => widget.controller.goToFirstPage(),
                  icon: const Icon(Icons.skip_previous)),
              IconButton(
                  onPressed: () => widget.controller.goToPreviousPage(),
                  icon: const Icon(Icons.chevron_left_sharp)),
              DropdownButton<int>(
                  onChanged: (v) => widget.controller.setRowsPerPage(v!),
                  value: _availableSizes.contains(widget.controller.rowsPerPage)
                      ? widget.controller.rowsPerPage
                      : _availableSizes[0],
                  dropdownColor: Colors.grey[800],
                  items: _availableSizes
                      .map((s) => DropdownMenuItem<int>(
                            value: s,
                            child: Text(s.toString()),
                          ))
                      .toList()),
              IconButton(
                  onPressed: () => widget.controller.goToNextPage(),
                  icon: const Icon(Icons.chevron_right_sharp)),
              IconButton(
                  onPressed: () => widget.controller.goToLastPage(),
                  icon: const Icon(Icons.skip_next))
            ],
          )),
    );
  }
}
