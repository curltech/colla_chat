import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/app_data_provider.dart';
import '../../provider/data_list_controller.dart';
import '../../provider/index_widget_provider.dart';
import '../../tool/util.dart';
import 'column_field_widget.dart';

class DataTableView<T> extends StatefulWidget {
  final List<ColumnFieldDef> columnDefs;
  late final DataListController<T> controller;
  final ScrollController scrollController = ScrollController();
  final Function()? onScrollMax;
  final Future<void> Function()? onRefresh;
  final Function(int index)? onTap;
  final String? routeName;
  final Function(bool?)? onSelectChanged;
  final Function(int index)? onLongPress;
  final List<DataColumn> dataColumns;

  DataTableView(
      {Key? key,
      required this.columnDefs,
      List<T> data = const [],
      int? currentIndex,
      this.onScrollMax,
      this.onRefresh,
      this.onTap,
      this.routeName,
      this.onSelectChanged,
      this.onLongPress,
      this.dataColumns = const []})
      : super(key: key) {
    controller = DataListController<T>(data: data, currentIndex: currentIndex);
  }

  @override
  State<StatefulWidget> createState() {
    return _DataListView<T>();
  }
}

class _DataListView<T> extends State<DataTableView> {
  int? sortColumnIndex;
  bool sortAscending = true;

  @override
  initState() {
    widget.controller.addListener(_update);
    var scrollController = widget.scrollController;
    scrollController.addListener(() {
      double offset = widget.scrollController.offset;
      logger.i('scrolled to $offset');

      ///判断是否滚动到最底，需要加载更多数据
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        logger.i('scrolled to max');
        if (widget.onScrollMax != null) {
          widget.onScrollMax!();
        }
      }
      if (scrollController.position.pixels ==
          scrollController.position.minScrollExtent) {
        logger.i('scrolled to min');
      }

      ///滚到指定的位置
      // widget.scrollController.animateTo(offset,
      //     duration: const Duration(milliseconds: 1000), curve: Curves.ease);
    });

    widget.dataColumns.clear();
    for (var columnDef in widget.columnDefs) {
      var dataColumn = DataColumn(
          label: Text(AppLocalizations.t(columnDef.label)),
          numeric: columnDef.dataType == DataType.int ||
              columnDef.dataType == DataType.double,
          tooltip: columnDef.hintText,
          onSort: columnDef.onSort ?? _onSort);
      widget.dataColumns.add(dataColumn);
    }

    super.initState();
  }

  _update() {
    setState(() {});
  }

  _onSort(int sortColumnIndex, bool sortAscending) {
    this.sortColumnIndex = sortColumnIndex;
    this.sortAscending = sortAscending;
    String name = widget.columnDefs[sortColumnIndex].name;
    widget.controller.sort(name, sortAscending);
  }

  bool _onNotification(ScrollNotification notification) {
    String type = notification.runtimeType.toString();
    logger.i('scrolled to $type');
    return true;
  }

  Future<void> _onRefresh() async {
    ///下拉刷新数据的地方，比如从数据库取更多数据
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  Widget _build(BuildContext context) {
    List data = widget.controller.data;
    List<DataRow> rows = [];
    for (var i = 0; i < data.length; ++i) {
      var d = data[i];
      var dataMap = JsonUtil.toMap(d);
      List<DataCell> cells = [];
      for (var columnDef in widget.columnDefs) {
        var value = dataMap[columnDef.name];
        var dataCell = DataCell(Text(value), onTap: () {
          widget.controller.currentIndex = i;
          var fn = widget.onTap;
          if (fn != null) {
            fn(i);
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
      if (i == widget.controller.currentIndex) {
        selected = true;
      }
      var dataRow = DataRow(
        cells: cells,
        selected: selected,
        onSelectChanged: (selected) {},
        onLongPress: () {
          var fn = widget.onLongPress;
          if (fn != null) {
            fn(i);
          }
        },
      );
      rows.add(dataRow);
    }
    Widget dataTableView = DataTable(
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      columns: widget.dataColumns,
      rows: rows,
    );

    return dataTableView;
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = _build(context);

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal, child: dataTableView);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
