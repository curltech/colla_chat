import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/data_list_controller.dart';
import '../../provider/index_widget_provider.dart';
import '../../tool/util.dart';
import 'column_field_widget.dart';

class DataTableView<T> extends StatefulWidget {
  final List<ColumnFieldDef> columnDefs;
  final DataListController<T> controller;
  final Function(int index)? onTap;
  final String? routeName;
  final Function(bool?)? onSelectChanged;
  final Function(int index)? onLongPress;
  final List<DataColumn> dataColumns = [];

  DataTableView({
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
    return _DataTableViewState<T>();
  }
}

class _DataTableViewState<T> extends State<DataTableView> {
  int? sortColumnIndex;
  bool sortAscending = true;

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
      var dataColumn = DataColumn(
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

  List<DataRow> _buildRows() {
    List<DataRow> rows = [];
    List data = widget.controller.data;
    for (int index = 0; index < data.length; ++index) {
      var d = data[index];
      var dataMap = JsonUtil.toMap(d);
      List<DataCell> cells = [];
      for (var columnDef in widget.columnDefs) {
        var value = dataMap[columnDef.name];
        value = value ?? '';
        var dataCell = DataCell(Text(value), onTap: () {
          widget.controller.currentIndex = index;
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
      var dataRow = DataRow(
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
      rows.add(dataRow);
    }
    return rows;
  }

  Widget _build(BuildContext context) {
    if (widget.dataColumns.isEmpty) {
      _buildColumnDefs();
    }
    Widget dataTableView = DataTable(
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      showCheckboxColumn: false,
      onSelectAll: (state) {},
      columns: widget.dataColumns,
      rows: _buildRows(),
    );

    return dataTableView;
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = _build(context);
    var layoutBuilder = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Column(
          children: [
            const Text(''),
            Container(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.minWidth),
                  child: dataTableView,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return layoutBuilder;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
