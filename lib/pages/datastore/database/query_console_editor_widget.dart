import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/idea.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:get/get.dart';
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
    return Obx(() {
      Map<String, dynamic>? data = queryResultController.data.firstOrNull;
      if (data == null) {
        return nilBox;
      }
      final List<PlatformDataColumn> queryResultDataColumns = [];
      for (var entry in data.entries) {
        String columnName = entry.key;
        dynamic columnValue = entry.value;
        if (columnValue is int) {
          queryResultDataColumns.add(PlatformDataColumn(
            label: columnName,
            name: columnName,
            dataType: DataType.int,
            align: TextAlign.right,
            // width: 70,
          ));
        } else if (columnValue is double) {
          queryResultDataColumns.add(PlatformDataColumn(
            label: columnName,
            name: columnName,
            dataType: DataType.double,
            align: TextAlign.right,
            // width: 70,
          ));
        } else {
          queryResultDataColumns.add(PlatformDataColumn(
            label: columnName,
            name: columnName,
            // width: 80,
          ));
        }
      }
      return BindingDataTable2<Map<String, dynamic>>(
        key: UniqueKey(),
        showCheckboxColumn: false,
        horizontalMargin: 0.0,
        columnSpacing: 0.0,
        platformDataColumns: queryResultDataColumns,
        controller: queryResultController,
        fixedLeftColumns: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: title,
        rightWidgets: [
          IconButton(
              onPressed: () async {
                String sql = codeController.fullText;
                DataSource? current = dataSourceController.current.value;
                if (current == null) {
                  return;
                }
                DataStore? dataStore = current.dataStore;
                if (dataStore == null) {
                  return;
                }
                List<Map<String, dynamic>> data =
                    await dataStore.select('select * from ($sql) limit 10');
                queryResultController.data.value = data;
              },
              icon: Icon(
                Icons.run_circle_outlined,
              ))
        ],
        child: Column(
          children: [
            SizedBox(
                height: 200,
                child: SingleChildScrollView(
                  child: CodeTheme(
                    data: CodeThemeData(styles: ideaTheme),
                    child: CodeField(
                      minLines: 10,
                      // maxLines: 10,
                      controller: codeController,
                    ),
                  ),
                )),
            Expanded(
                child: Card(
                    elevation: 0.0,
                    margin: EdgeInsets.zero,
                    shape: ContinuousRectangleBorder(),
                    child: _buildQueryResultListView(context)))
          ],
        ));
  }
}
