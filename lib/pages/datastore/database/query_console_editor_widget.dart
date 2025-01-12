import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/sql.dart';

class QueryConsoleEditorWidget extends StatelessWidget with TileDataMixin {
  QueryConsoleEditorWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'query_console_editor';

  @override
  IconData get iconData => Icons.mode_edit_outline_rounded;

  @override
  String get title => 'QueryConsoleEditor';

  final codeController = CodeController(
    language: sql,
  );

  final DataListController<Map<String, dynamic>> queryResultController =
      DataListController<Map<String, dynamic>>();

  Widget _buildQueryResultListView(BuildContext context) {
    Map<String, dynamic>? data = queryResultController.data.firstOrNull;
    if (data == null) {
      return nilBox;
    }
    final List<PlatformDataColumn> queryResultDataColumns = [];
    for (var entry in data.entries) {
      String columnName = entry.key;
      dynamic columnValue = entry.value;
      if (columnValue is int || columnValue is double) {
        queryResultDataColumns.add(PlatformDataColumn(
          label: columnName,
          name: columnName,
          dataType: DataType.double,
          align: TextAlign.right,
          width: 70,
        ));
      } else {
        queryResultDataColumns.add(PlatformDataColumn(
          label: columnName,
          name: columnName,
          width: 80,
        ));
      }
    }
    return BindingDataTable2<Map<String, dynamic>>(
      key: UniqueKey(),
      showCheckboxColumn: true,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: queryResultDataColumns,
      controller: queryResultController,
      fixedLeftColumns: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OverflowBar(
          alignment: MainAxisAlignment.start,
          children: [
            IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.run_circle_outlined,
                  color: myself.primary,
                ))
          ],
        ),
        SizedBox(
            height: 300,
            child: CodeTheme(
              data: CodeThemeData(styles: monokaiSublimeTheme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: codeController,
                ),
              ),
            )),
        Expanded(child: _buildQueryResultListView(context))
      ],
    );
  }
}
