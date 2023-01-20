import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

///PlutoGrid，一个功能非常强大的表格实现
class PlutoDataGridWidget<T> extends StatefulWidget {
  final List<ColumnFieldDef> columnDefs;
  final DataPageController<T> controller;
  final Function(int index)? onTap;
  final String? routeName;
  final Function(bool?)? onSelectChanged;
  final Function(int index)? onLongPress;
  final List<PlutoColumn> dataColumns = [];

  PlutoDataGridWidget({
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

class _PaginatedDataTableState<T> extends State<PlutoDataGridWidget> {
  late PlutoGridStateManager stateManager;
  bool autoEditing = false;

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
      var type = PlutoColumnType.text();
      if (columnDef.dataType == DataType.int ||
          columnDef.dataType == DataType.double) {
        type = PlutoColumnType.number();
      } else if (columnDef.dataType == DataType.set ||
          columnDef.dataType == DataType.list) {
        var options = columnDef.options;
        if (options != null) {
          type = PlutoColumnType.select(
            options,
            enableColumnFilter: columnDef.enableColumnFilter,
          );
        }
      } else if (columnDef.dataType == DataType.date) {
        type = PlutoColumnType.date();
      } else if (columnDef.dataType == DataType.time) {
        type = PlutoColumnType.time();
      }
      var dataColumn = PlutoColumn(
          title: AppLocalizations.t(columnDef.label),
          field: columnDef.name,
          type: type,
          sort: PlutoColumnSort.ascending);
      widget.dataColumns.add(dataColumn);
    }
  }

  Future<List<PlutoRow>> fetchRows() async {
    await widget.controller.first();
    List<PlutoRow> rows = _buildRows();

    return rows;
  }

  onTap(int index) {
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
  }

  List<PlutoRow> _buildRows() {
    List<PlutoRow> rows = [];
    List data = widget.controller.pagination.data;
    for (int index = 0; index < data.length; ++index) {
      var d = data[index];
      var dataMap = JsonUtil.toJson(d);
      Map<String, PlutoCell> cells = {};
      for (var columnDef in widget.columnDefs) {
        var value = dataMap[columnDef.name];
        value = value ?? '';
        var dataCell = PlutoCell(value: value);
        cells[columnDef.name] = dataCell;
      }
      var dataRow = PlutoRow(
        cells: cells,
      );
      rows.add(dataRow);
    }
    return rows;
  }

  void toggleAutoEditing(bool flag) {
    setState(() {
      autoEditing = flag;
      stateManager.setAutoEditing(flag);
    });
  }

  Widget _build(BuildContext context) {
    if (widget.dataColumns.isEmpty) {
      _buildColumnDefs();
    }
    Widget dataTableView = PlutoGrid(
        columns: widget.dataColumns,
        rows: _buildRows(),
        onLoaded: (PlutoGridOnLoadedEvent event) {
          event.stateManager.setSelectingMode(PlutoGridSelectingMode.cell);

          stateManager = event.stateManager;
        },
        onChanged: (PlutoGridOnChangedEvent event) {},
        onSelected: (PlutoGridOnSelectedEvent event) {
          ///进入路由
          ///event.row
        },
        onRowChecked: (PlutoGridOnRowCheckedEvent event) {},
        onRowDoubleTap: (PlutoGridOnRowDoubleTapEvent event) {
          onTap(event.rowIdx!);
        },
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
          enableColumnBorder: false,
          gridBorderColor: Colors.white,
          borderColor: Colors.white,
          activatedBorderColor: Colors.white,
          inactivatedBorderColor: Colors.white,
          localeText: PlutoGridLocaleText.china(),
        ),
        mode: PlutoGridMode.normal);

    return dataTableView;
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = _build(context);
    var width = appDataProvider.totalSize.width;
    var height = appDataProvider.totalSize.height - appDataProvider.toolbarHeight;
    var view = SizedBox(width: width, height: height, child: dataTableView);

    return view;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

// void _defaultExportGridAsCSV() async {
//   String title = "pluto_grid_export";
//   var exported = const Utf8Encoder()
//       .convert(pluto_grid_export.PlutoGridExport.exportCSV(stateManager));
//   await FileSaver.instance.saveFile("$title.csv", exported, ".csv");
// }
//
// void _defaultExportGridAsCSVCompatibleWithExcel() async {
//   String title = "pluto_grid_export";
//   var exportCSV = pluto_grid_export.PlutoGridExport.exportCSV(stateManager);
//   var exported = const Utf8Encoder().convert(
//       // FIX Add starting \u{FEFF} / 0xEF, 0xBB, 0xBF
//       // This allows open the file in Excel with proper character interpretation
//       // See https://stackoverflow.com/a/155176
//       '\u{FEFF}$exportCSV');
//   await FileSaver.instance.saveFile("$title.csv", exported, ".csv");
// }
//
// void _defaultExportGridAsCSVFakeExcel() async {
//   String title = "pluto_grid_export";
//   var exportCSV = pluto_grid_export.PlutoGridExport.exportCSV(stateManager);
//   var exported = const Utf8Encoder().convert(
//       // FIX Add starting \u{FEFF} / 0xEF, 0xBB, 0xBF
//       // This allows open the file in Excel with proper character interpretation
//       // See https://stackoverflow.com/a/155176
//       '\u{FEFF}$exportCSV');
//   await FileSaver.instance.saveFile("$title.xls", exported, ".xls");
// }
//
// // void _exportGridAsTSV() async {
// //   String title = "pluto_grid_export";
// //   var exported = const Utf8Encoder().convert(PlutoGridExport.exportCSV(
// //     widget.stateManager,
// //     fieldDelimiter: "\t",
// //   ));
// //   await FileSaver.instance.saveFile("$title.csv", exported, ".csv");
// // }
//
// void _defaultExportGridAsCSVWithSemicolon() async {
//   String title = "pluto_grid_export";
//   var exported =
//       const Utf8Encoder().convert(pluto_grid_export.PlutoGridExport.exportCSV(
//     stateManager,
//     fieldDelimiter: ";",
//   ));
//   await FileSaver.instance.saveFile("$title.csv", exported, ".csv");
// }
//
// void _printToPdfAndShareOrSave() async {
//   final themeData = pluto_grid_export.ThemeData.withFont(
//     base: pluto_grid_export.Font.ttf(
//       await rootBundle.load('assets/fonts/open_sans/OpenSans-Regular.ttf'),
//     ),
//     bold: pluto_grid_export.Font.ttf(
//       await rootBundle.load('assets/fonts/open_sans/OpenSans-Bold.ttf'),
//     ),
//   );
//
//   var plutoGridPdfExport = pluto_grid_export.PlutoGridDefaultPdfExport(
//     title: "Pluto Grid Sample pdf print",
//     creator: "Pluto Grid Rocks!",
//     format: pluto_grid_export.PdfPageFormat.a4.landscape,
//     themeData: themeData,
//   );
//
//   await pluto_grid_export.Printing.sharePdf(
//       bytes: await plutoGridPdfExport.export(stateManager),
//       filename: plutoGridPdfExport.getFilename());
// }
}
