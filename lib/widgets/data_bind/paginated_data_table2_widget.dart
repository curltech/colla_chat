import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/app_data_provider.dart';
import '../../provider/data_list_controller.dart';
import '../../provider/index_widget_provider.dart';
import '../data_bind/column_field_widget.dart';

///系统提供的分页表格只能用于静态展示，不能进行增加删除等操作
///因为其计算记录的方法很粗糙，某页发生增删时不适用，自己实现新的会更好
class PaginatedDataTable2Widget<T> extends StatefulWidget {
  final List<ColumnFieldDef> columnDefs;
  final DataPageController<T> controller;
  final Function(int index)? onTap;
  final String? routeName;
  final Function(bool?)? onSelectChanged;
  final Function(int index)? onLongPress;
  final List<DataColumn> dataColumns = [];

  PaginatedDataTable2Widget({
    Key? key,
    required this.columnDefs,
    this.onTap,
    this.routeName,
    this.onSelectChanged,
    this.onLongPress,
    required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PaginatedDataTableState<T>();
  }
}

class _PaginatedDataTableState<T> extends State<PaginatedDataTable2Widget> {
  int? sortColumnIndex;
  bool sortAscending = true;
  final PaginatorController _controller = PaginatorController();

  @override
  initState() {
    widget.controller.addListener(_update);
    _buildColumnDefs();
    super.initState();
  }

  _update() {
    setState(() {});
  }

  _buildColumnDefs() {
    if (widget.dataColumns.isNotEmpty) {
      widget.dataColumns.clear();
    }
    for (var columnDef in widget.columnDefs) {
      var dataColumn = DataColumn2(
          label: Text(AppLocalizations.t(columnDef.label)),
          numeric: columnDef.dataType == DataType.int ||
              columnDef.dataType == DataType.double,
          tooltip: columnDef.hintText,
          onSort: columnDef.onSort ?? _onSort);
      widget.dataColumns.add(dataColumn);
    }
  }

  _onSort(int sortColumnIndex, bool sortAscending) {
    this.sortColumnIndex = sortColumnIndex;
    this.sortAscending = sortAscending;
    String name = widget.columnDefs[sortColumnIndex].name;
    widget.controller.sort(name, sortAscending);
  }

  Widget _build(BuildContext context) {
    if (widget.dataColumns.isEmpty) {
      _buildColumnDefs();
    }
    var sourceData = DataPageSource<T>(widget: widget, context: context);
    int rowsPerPage = widget.controller.pagination.data.length;
    Widget dataTableView = PaginatedDataTable2(
      actions: [],
      rowsPerPage: rowsPerPage,
      initialFirstRowIndex: 0,
      onPageChanged: (i) {
        logger.i('go $i page');
        widget.controller.move(i);
      },
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      showCheckboxColumn: false,
      onSelectAll: (state) {},
      columns: widget.dataColumns,
      source: sourceData,
    );

    return dataTableView;
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = _build(context);
    var width = appDataProvider.size.width;
    var view = Card(
      child: dataTableView,
    );

    return view;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}

class DataPageSource<T> extends DataTableSource {
  final BuildContext context;
  final PaginatedDataTable2Widget widget;

  DataPageSource({required this.widget, required this.context});

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => widget.controller.pagination.rowsNumber;

  @override
  int get selectedRowCount => 0;

  @override
  DataRow getRow(int index) {
    List data = widget.controller.pagination.data;
    var length = data.length;
    index = index % length;
    var d = data[index];
    var dataMap = JsonUtil.toJson(d);
    List<DataCell> cells = [];
    for (var columnDef in widget.columnDefs) {
      var value = dataMap[columnDef.name];
      value = value ?? '';
      var dataCell = DataCell(Text(value.toString()), onTap: () {
        widget.controller.setCurrentIndex(index);
        var fn = widget.onTap;
        if (fn != null) {
          fn(index);
        } else {
          ///如果路由名称存在，点击会调用路由
          if (widget.routeName != null) {
            var indexWidgetProvider =
                Provider.of<IndexWidgetProvider>(context, listen: false);
            indexWidgetProvider.push(widget.routeName!, context: context);
          }
        }
      });
      cells.add(dataCell);
    }
    var selected = false;
    if (index == widget.controller.currentIndex) {
      selected = true;
    }
    var dataRow = DataRow2(
      cells: cells,
      selected: selected,
      onSelectChanged: (selected) {},
      onLongPress: () {
        var fn = widget.onLongPress;
        if (fn != null) {
          fn(index);
        }
      },
    );
    return dataRow;
  }
}
