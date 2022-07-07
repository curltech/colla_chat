import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../provider/app_data_provider.dart';
import '../../provider/data_list_controller.dart';
import '../../tool/util.dart';
import 'column_field_widget.dart';

///Syncfusion DataGrid
class DataGridWidget<T> extends StatefulWidget {
  final List<ColumnFieldDef> columnDefs;
  final DataPageController<T> controller;
  final DataGridSource dataGridSource;
  final Function(int index)? onTap;
  final String? routeName;
  final Function(bool?)? onSelectChanged;
  final List<GridColumn> dataColumns = [];

  DataGridWidget({
    Key? key,
    required this.columnDefs,
    this.onTap,
    this.routeName,
    this.onSelectChanged,
    required this.controller,
    required this.dataGridSource,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PaginatedDataTableState<T>();
  }
}

class _PaginatedDataTableState<T> extends State<DataGridWidget> {
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
      var dataColumn = GridColumn(
          columnName: columnDef.name,
          label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                AppLocalizations.t(columnDef.label),
                overflow: TextOverflow.ellipsis,
              )));
      widget.dataColumns.add(dataColumn);
    }
  }

  Widget _build(BuildContext context) {
    if (widget.dataColumns.isEmpty) {
      _buildColumnDefs();
    }
    Widget dataTableView = SfDataGrid(
      showCheckboxColumn: false,
      onSelectionChanged: (List<DataGridRow> rows1, List<DataGridRow> rows2) {},
      columns: widget.dataColumns,
      source: widget.dataGridSource,
    );

    return dataTableView;
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = _build(context);
    var width = appDataProvider.size.width - appDataProvider.leftBarWidth;
    var view = SingleChildScrollView(
      controller: ScrollController(),
      child: Card(
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: width),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: dataTableView),
        ),
      ),
    );

    return view;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}

class ListDataGridSource<T> extends DataGridSource {
  final List<ColumnFieldDef> columnDefs;
  List<DataGridRow> _rows = [];

  ListDataGridSource({required this.columnDefs, required List<T> data}) {
    _rows = _buildRows(data);
  }

  @override
  List<DataGridRow> get rows => _rows;

  List<DataGridRow> _buildRows(List<T> data) {
    List<DataGridRow> rows = [];
    for (int index = 0; index < data.length; ++index) {
      var d = data[index];
      var dataMap = JsonUtil.toMap(d);
      List<DataGridCell> cells = [];
      for (var columnDef in columnDefs) {
        var value = dataMap[columnDef.name];
        value = value ?? '';
        var dataCell = DataGridCell(columnName: columnDef.name, value: value);
        cells.add(dataCell);
      }
      var dataRow = DataGridRow(
        cells: cells,
      );
      rows.add(dataRow);
    }
    return rows;
  }

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((dataGridCell) {
      return Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.all(16.0),
        child: Text(dataGridCell.value.toString()),
      );
    }).toList());
  }
}
