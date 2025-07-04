import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/tool/pagination_util.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:flutter/material.dart';

class BindingPaginatedDataTable2<T> extends StatelessWidget {
  final List<PlatformDataColumn> platformDataColumns;
  final DataPageController<T> controller;
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
    super.key,
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
  });

  /// 过滤条件的多项选择框的表
  Widget _buildDataTable(BuildContext context) {
    return BindingTrinaDataGrid(
      key: UniqueKey(),
      dataRowHeight: dataRowHeight,
      minWidth: minWidth,
      showCheckboxColumn: showCheckboxColumn,
      horizontalMargin: horizontalMargin,
      columnSpacing: columnSpacing,
      fixedLeftColumns: fixedLeftColumns,
      platformDataColumns: platformDataColumns,
      controller: controller,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      onSelectChanged: onSelectChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = Column(
      children: [
        BindingPager(controller),
        Expanded(child: _buildDataTable(context)),
      ],
    );

    return dataTableView;
  }
}

/// 分页器组件
class BindingPager extends StatelessWidget {
  const BindingPager(this.controller, {super.key});

  final DataPageController controller;

  static const List<int> _availableSizes = [3, 5, 10, 20, 50, 100, 500];

  Widget _buildPageNumber() {
    return ListenableBuilder(
        listenable: controller.findCondition,
        builder: (BuildContext context, Widget? child) {
          int currentPage = PaginationUtil.getCurrentPage(
              controller.findCondition.value.offset,
              controller.findCondition.value.limit);
          int totalPage = PaginationUtil.getPageCount(
              controller.findCondition.value.count,
              controller.findCondition.value.limit);
          return Text(
              '${AppLocalizations.t('Page/TotalPage')}:$currentPage/$totalPage');
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
              tooltip: AppLocalizations.t('First'),
              onPressed: () => controller.first(),
              icon: const Icon(Icons.skip_previous)),
          IconButton(
              tooltip: AppLocalizations.t('Previous'),
              onPressed: () => controller.previous(),
              icon: const Icon(Icons.chevron_left_sharp)),
          _buildPageNumber(),
          IconButton(
              tooltip: AppLocalizations.t('Next'),
              onPressed: () => controller.next(),
              icon: const Icon(Icons.chevron_right_sharp)),
          IconButton(
              tooltip: AppLocalizations.t('Last'),
              onPressed: () => controller.last(),
              icon: const Icon(Icons.skip_next)),
          Text('${AppLocalizations.t('Records per page')}:'),
          ListenableBuilder(
              listenable: controller.findCondition,
              builder: (BuildContext context, Widget? child) {
                return DropdownButton<int>(
                    onChanged: (v) {
                      controller.findCondition.value = controller
                          .findCondition.value
                          .copy(offset: 0, limit: v!);
                    },
                    value: _availableSizes
                            .contains(controller.findCondition.value.limit)
                        ? controller.findCondition.value.limit
                        : _availableSizes[0],
                    items: _availableSizes
                        .map((s) => DropdownMenuItem<int>(
                              value: s,
                              child: Text(s.toString()),
                            ))
                        .toList());
              })
        ],
      ),
    );
  }
}
