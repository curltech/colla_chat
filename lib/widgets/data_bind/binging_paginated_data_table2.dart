import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';

class BindingPaginatedDataTable2<T> extends StatefulWidget {
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
  @override
  initState() {
    widget.controller.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  /// 过滤条件的多项选择框的表
  Widget _buildDataTable(BuildContext context) {
    return BindingDataTable2(
      key: UniqueKey(),
      dataRowHeight: widget.dataRowHeight,
      minWidth: widget.minWidth ?? 2000,
      showCheckboxColumn: widget.showCheckboxColumn,
      horizontalMargin: widget.horizontalMargin,
      columnSpacing: widget.columnSpacing,
      fixedLeftColumns: widget.fixedLeftColumns,
      platformDataColumns: widget.platformDataColumns,
      controller: widget.controller,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      onSelectChanged: widget.onSelectChanged,
    );
  }

  Widget _buildPageNumber() {
    int currentPage =
        ((widget.controller.currentIndex + 1) / widget.controller.limit)
                .floor() +
            1;
    int totalPage = (widget.controller.limit).ceil();

    return Text('${AppLocalizations.t('Page:')}$currentPage/$totalPage');
  }

  @override
  Widget build(BuildContext context) {
    var dataTableView = Column(
      children: [
        BindingPager(widget.controller),
        Expanded(child: _buildDataTable(context)),
      ],
    );

    return dataTableView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}

/// 分页器组件
class BindingPager extends StatefulWidget {
  const BindingPager(this.controller, {super.key});

  final DataPageController controller;

  @override
  BindingPagerState createState() => BindingPagerState();
}

class BindingPagerState extends State<BindingPager> {
  static const List<int> _availableSizes = [3, 5, 10, 20];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {}

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
              tooltip: AppLocalizations.t('First'),
              onPressed: () => widget.controller.first(),
              icon: const Icon(Icons.skip_previous)),
          IconButton(
              tooltip: AppLocalizations.t('Previous'),
              onPressed: () => widget.controller.previous(),
              icon: const Icon(Icons.chevron_left_sharp)),
          // DropdownButton<int>(
          //     onChanged: (v) {
          //       widget.controller.limit = v!;
          //     },
          //     value: _availableSizes.contains(widget.controller.limit)
          //         ? widget.controller.limit
          //         : _availableSizes[0],
          //     items: _availableSizes
          //         .map((s) => DropdownMenuItem<int>(
          //               value: s,
          //               child: Text(s.toString()),
          //             ))
          //         .toList()),
          IconButton(
              tooltip: AppLocalizations.t('Next'),
              onPressed: () => widget.controller.next(),
              icon: const Icon(Icons.chevron_right_sharp)),
          IconButton(
              tooltip: AppLocalizations.t('Last'),
              onPressed: () => widget.controller.last(),
              icon: const Icon(Icons.skip_next))
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
