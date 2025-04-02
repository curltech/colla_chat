import 'dart:async';

import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_paginated_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/idea.dart';
import 'package:get/get.dart';
import 'package:highlight/languages/sql.dart';

final codeController = CodeController(
  language: sql,
);

class QueryResultController extends DataPageController<Map<String, dynamic>> {
  @override
  FutureOr<void> findData() async {
    String sql = codeController.text;
    DataSource? current = dataSourceController.current as DataSource?;
    if (current == null) {
      return null;
    }
    DataStore? dataStore = current.dataStore;
    if (dataStore == null) {
      return null;
    }
    List<Map<String, dynamic>> data = await dataStore.select(
        'select * from ($sql) limit ${findCondition.value.limit} offset ${findCondition.value.offset}');
    replaceAll(data);
  }
}

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

  final QueryResultController queryResultController = QueryResultController();

  Widget _buildQueryResultListView(BuildContext context) {
    return Obx(() {
      Map<String, dynamic>? data = queryResultController.data.firstOrNull;
      if (data == null) {
        return Center(child: Text('No data'));
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
      return BindingPaginatedDataTable2<Map<String, dynamic>>(
        key: UniqueKey(),
        showCheckboxColumn: false,
        horizontalMargin: 10.0,
        columnSpacing: 0.0,
        platformDataColumns: queryResultDataColumns,
        controller: queryResultController,
        fixedLeftColumns: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    queryResultController.replaceAll([]);
    return AppBarView(
        withLeading: true,
        title: title,
        rightWidgets: [
          IconButton(
              onPressed: () async {
                DataSource? current = dataSourceController.current as DataSource?;
                if (current == null) {
                  return;
                }
                DataStore? dataStore = current.dataStore;
                if (dataStore == null) {
                  return;
                }
                try {
                  await queryResultController.findData();
                } catch (e) {
                  DialogUtil.error(content: 'execute sql failure:$e');
                }
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
