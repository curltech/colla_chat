import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:flutter/material.dart';

class BindingTrinaMoreDataGrid<T> extends StatelessWidget {
  final List<PlatformDataColumn> platformDataColumns;
  final DataPageController<T> controller;
  final bool showCheckboxColumn;
  final double? rowHeight;
  final double? columnHeight;
  final double? minWidth;
  final double horizontalMargin;
  final double columnSpacing;
  final int fixedLeftColumns;
  final Function(int index)? onDoubleTap;
  final Function(int, List<dynamic>?)? onSelected;
  final Function(int?, bool?)? onRowChecked;
  final Function(int, dynamic)? onChanged;
  final Function(int, dynamic)? onLongPress;
  final Future<void> Function()? onRefresh;

  const BindingTrinaMoreDataGrid({
    super.key,
    required this.platformDataColumns,
    this.onSelected,
    this.onLongPress,
    this.onChanged,
    this.onRowChecked,
    required this.controller,
    this.onDoubleTap,
    this.onRefresh,
    this.showCheckboxColumn = true,
    this.rowHeight,
    this.columnHeight,
    this.minWidth,
    this.horizontalMargin = 24.0,
    this.columnSpacing = 56.0,
    this.fixedLeftColumns = 0,
  });

  Future<void> _onRefresh() async {
    ///下拉刷新数据的地方，比如从数据库取更多数据
    if (onRefresh == null) {
      controller.next();
    } else {
      await (onRefresh!)();
    }
  }

  /// 过滤条件的多项选择框的表
  Widget _buildDataTable(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _onRefresh,
        //notificationPredicate: _notificationPredicate,
        child: BindingTrinaDataGrid(
          key: UniqueKey(),
          rowHeight: rowHeight,
          columnHeight: columnHeight,
          minWidth: minWidth ?? 2000,
          showCheckboxColumn: showCheckboxColumn,
          horizontalMargin: horizontalMargin,
          columnSpacing: columnSpacing,
          fixedLeftColumns: fixedLeftColumns,
          platformDataColumns: platformDataColumns,
          controller: controller,
          onDoubleTap: onDoubleTap,
          onLongPress: onLongPress,
          onChanged: onChanged,
          onSelected: onSelected,
          onRowChecked: onRowChecked,
        ));
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = Column(
      children: [
        _buildDataTable(context),
      ],
    );

    return dataTableView;
  }
}
