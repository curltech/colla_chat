import 'package:colla_chat/l10n/localization.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/data_list_controller.dart';
import '../../provider/index_widget_provider.dart';
import '../../tool/util.dart';
import 'column_field_widget.dart';

class DataTable2Widget<T> extends StatefulWidget {
  final List<ColumnFieldDef> columnDefs;
  final DataListController<T> controller;
  final Function(int index)? onTap;
  final String? routeName;
  final Function(bool?)? onSelectChanged;
  final Function(int index)? onLongPress;
  final List<DataColumn> dataColumns = [];

  DataTable2Widget({
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
    return _DataTable2WidgetState<T>();
  }
}

class _DataTable2WidgetState<T> extends State<DataTable2Widget> {
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

  List<DataRow2> _buildRows() {
    List<DataRow2> rows = [];
    List data = widget.controller.data;
    for (int index = 0; index < data.length; ++index) {
      var d = data[index];
      var dataMap = JsonUtil.toJson(d);
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
            ///????????????????????????????????????????????????
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
      rows.add(dataRow);
    }
    return rows;
  }

  Widget _build(BuildContext context) {
    if (widget.dataColumns.isEmpty) {
      _buildColumnDefs();
    }
    Widget dataTableView = DataTable2(
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
    var card = Card(
      child: dataTableView,
    );

    return card;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
