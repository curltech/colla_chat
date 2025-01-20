import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_column_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_index_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart'
    as data_source;
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/idea.dart';
import 'package:get/get.dart';
import 'package:highlight/languages/sql.dart';
import 'package:tab_container/tab_container.dart';

final Rx<data_source.DataTable?> rxDataTable = Rx<data_source.DataTable?>(null);

class DataTableEditWidget extends StatefulWidget with TileDataMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_table_edit';

  @override
  IconData get iconData => Icons.table_view_outlined;

  @override
  String get title => 'DataTableEdit';

  DataTableEditWidget({super.key}) {
    _buildDataColumns();
    _buildDataIndexes();
    rxDataTable.addListener(() {
      _buildDataColumns();
      _buildDataIndexes();
    });
  }

  final DataListController<data_source.DataColumn> dataColumnController =
      DataListController<data_source.DataColumn>();

  final DataListController<data_source.DataIndex> dataIndexController =
      DataListController<data_source.DataIndex>();

  @override
  State<StatefulWidget> createState() => _DataTableEditWidgetState();

  _buildDataColumns() async {
    data_source.DataTable dataTable = rxDataTable.value!;
    if (dataTable.name == null) {
      return null;
    }
    List<data_source.DataColumn>? dataColumns =
        await dataSourceController.findColumns(dataTable.name!);
    if (dataColumns == null) {
      return null;
    }
    dataColumnController.data.assignAll(dataColumns);
  }

  _buildDataIndexes() async {
    data_source.DataTable dataTable = rxDataTable.value!;
    if (dataTable.name == null) {
      return null;
    }
    List<data_source.DataIndex>? dataIndexes =
        await dataSourceController.findIndexes(dataTable.name!);
    if (dataIndexes == null) {
      return null;
    }
    dataIndexController.data.assignAll(dataIndexes);
  }
}

class _DataTableEditWidgetState extends State<DataTableEditWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
  }

  List<PlatformDataField> buildDataTableDataFields(String sourceType) {
    var dataSourceDataFields = [
      PlatformDataField(
          name: 'name',
          label: 'Name',
          prefixIcon: Icon(Icons.person, color: myself.primary)),
      PlatformDataField(
          name: 'comment',
          label: 'Comment',
          prefixIcon: Icon(Icons.comment, color: myself.primary)),
    ];

    return dataSourceDataFields;
  }

  FormInputController? formInputController;

  //DataTableNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    return Obx(() {
      data_source.DataTable dataTable = rxDataTable.value!;
      List<PlatformDataField> dataSourceDataFields =
          buildDataTableDataFields(SourceType.sqlite.name);
      formInputController = FormInputController(dataSourceDataFields);

      formInputController?.setValues(JsonUtil.toJson(dataTable));
      var formInputWidget = FormInputWidget(
        spacing: 10.0,
        height: 160,
        onOk: (Map<String, dynamic> values) {
          _onOk(values);
        },
        controller: formInputController!,
        formButtons: [
          FormButton(
              label: 'Generate',
              onTap: (Map<String, dynamic> values) async {
                await _onOk(values);
                String? sql = _buildSql();

                if (sql != null) {
                  codeController.fullText = sql;
                }
              }),
          FormButton(
              label: 'Execute',
              onTap: (Map<String, dynamic> values) async {
                await _onOk(values);
                String? sql = _buildSql();

                if (sql != null) {
                  var result = dataSourceController.current.value?.dataStore
                      ?.run(Sql(sql));
                  logger.i('execute sql result:$result');
                }
              })
        ],
      );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
        child: formInputWidget,
      );
    });
  }

  Future<data_source.DataTable?> _onOk(Map<String, dynamic> values) async {
    data_source.DataTable current = data_source.DataTable.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has dataTable name'));
      return null;
    }
    data_source.DataTable dataTable = rxDataTable.value!;
    String? originalName = dataTable.name;
    if (originalName == null) {
      dataTable.name = current.name;
      dataTable.comment = current.comment;
    } else {
      dataTable.name = current.name;
      dataTable.comment = current.comment;
    }

    DialogUtil.info(content: 'Successfully update dataTable:${dataTable.name}');

    return current;
  }

  Widget _buildDataColumnsWidget(BuildContext context) {
    final List<PlatformDataColumn> platformDataColumns = [];
    platformDataColumns.add(PlatformDataColumn(
      label: 'Name',
      name: 'name',
      dataType: DataType.string,
      align: TextAlign.left,
    ));
    platformDataColumns.add(PlatformDataColumn(
      label: 'DataType',
      name: 'dataType',
      dataType: DataType.string,
      align: TextAlign.left,
    ));
    platformDataColumns.add(PlatformDataColumn(
      label: 'isKey',
      name: 'isKey',
      dataType: DataType.bool,
      align: TextAlign.right,
    ));

    return BindingDataTable2<data_source.DataColumn>(
      key: UniqueKey(),
      showCheckboxColumn: true,
      horizontalMargin: 15.0,
      columnSpacing: 0.0,
      platformDataColumns: platformDataColumns,
      controller: widget.dataColumnController,
      fixedLeftColumns: 0,
    );
  }

  String? _getCheckedColumnNames() {
    List<data_source.DataColumn> dataColumns =
        widget.dataColumnController.checked;
    if (dataColumns.isEmpty) {
      return null;
    }
    String names = '';
    for (int i = 0; i < dataColumns.length; ++i) {
      data_source.DataColumn dataColumn = dataColumns[i];
      if (i > 0) {
        names += ',';
      }
      names += dataColumn.name!;
    }

    return names;
  }

  Widget _buildColumnButtonWidget(BuildContext context) {
    return OverflowBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            tooltip: AppLocalizations.t('New column'),
            onPressed: () {
              data_source.DataTable dataTable = rxDataTable.value!;
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              data_source.DataColumn dataColumn = data_source.DataColumn();
              rxDataColumn.value = dataColumn;
              widget.dataColumnController.data.add(dataColumn);
              widget.dataColumnController.setCurrentIndex =
                  widget.dataColumnController.data.length - 1;
              indexWidgetProvider.push('data_column_edit');
            },
            icon: Icon(
              Icons.add,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Delete column'),
            onPressed: () {
              data_source.DataTable dataTable = rxDataTable.value!;
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              List<data_source.DataColumn> dataColumns =
                  widget.dataColumnController.checked;
              if (dataColumns.isEmpty) {
                return;
              }
              for (data_source.DataColumn dataColumn in dataColumns) {
                widget.dataColumnController.data.remove(dataColumn);
                dataSourceController.current.value?.dataStore?.run(Sql(
                    'alter table ${dataTable.name} drop column ${dataColumn.name};'));
              }
            },
            icon: Icon(Icons.remove, color: myself.primary)),
        IconButton(
            tooltip: AppLocalizations.t('Edit column'),
            onPressed: () {
              data_source.DataTable dataTable = rxDataTable.value!;
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              rxDataColumn.value = widget.dataColumnController.current;
              indexWidgetProvider.push('data_column_edit');
            },
            icon: Icon(Icons.edit, color: myself.primary)),
      ],
    );
  }

  Widget _buildIndexButtonWidget(BuildContext context) {
    return OverflowBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            tooltip: AppLocalizations.t('New index'),
            onPressed: () {
              data_source.DataTable dataTable = rxDataTable.value!;
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              String? columnNames = _getCheckedColumnNames();
              if (columnNames == null) {
                DialogUtil.error(content: 'Please choose column of index');
                return;
              }
              data_source.DataIndex dataIndex = data_source.DataIndex();
              dataIndex.name = '${dataTable.name}_${columnNames}_index';
              dataIndex.columnNames = columnNames;
              widget.dataColumnController.setCheckAll(false);
              rxDataIndex.value = dataIndex;
              widget.dataIndexController.data.add(dataIndex);
              widget.dataIndexController.setCurrentIndex =
                  widget.dataIndexController.data.length - 1;
              indexWidgetProvider.push('data_index_edit');
            },
            icon: Icon(
              Icons.add,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Delete index'),
            onPressed: () {
              data_source.DataTable dataTable = rxDataTable.value!;
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              List<data_source.DataIndex> dataIndexes =
                  widget.dataIndexController.checked;
              if (dataIndexes.isEmpty) {
                return;
              }
              for (data_source.DataIndex dataIndex in dataIndexes) {
                widget.dataIndexController.data.remove(dataIndex);
                dataSourceController.current.value?.dataStore
                    ?.run(Sql('drop index ${dataIndex.name}'));
              }
            },
            icon: Icon(Icons.remove, color: myself.primary)),
        IconButton(
            tooltip: AppLocalizations.t('Edit index'),
            onPressed: () {
              data_source.DataTable dataTable = rxDataTable.value!;
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              rxDataIndex.value = widget.dataIndexController.current;
              indexWidgetProvider.push('data_index_edit');
            },
            icon: Icon(Icons.edit, color: myself.primary)),
      ],
    );
  }

  final codeController = CodeController(
    language: sql,
  );

  String? _buildTableSql() {
    String? tableName = formInputController?.controllers['name']?.value;
    if (tableName == null) {
      return null;
    }
    String sql = 'create table $tableName\n';
    sql += '(\n';
    List<data_source.DataColumn> dataColumns = widget.dataColumnController.data;
    if (dataColumns.isNotEmpty) {
      String keyColumns = '';
      for (int i = 0; i < dataColumns.length; ++i) {
        data_source.DataColumn dataColumn = dataColumns[i];
        String columnName = dataColumn.name!;
        String dataType = dataColumn.dataType!;
        bool? notNull = dataColumn.notNull;
        if (notNull != null && notNull) {
          sql += '    $columnName   $dataType not null,\n';
        } else {
          sql += '    $columnName   $dataType,\n';
        }
        if (dataColumn.isKey != null && dataColumn.isKey!) {
          if (keyColumns.isEmpty) {
            keyColumns += columnName;
          } else {
            keyColumns += ',$columnName';
          }
        }
      }
      if (keyColumns.isNotEmpty) {
        sql += '    constraint ${tableName}_pk\n';
        sql += '    primary key($keyColumns)\n';
      }
    }
    sql += ');';

    return sql;
  }

  String? _buildIndexSql() {
    String? tableName = formInputController?.controllers['name']?.value;
    if (tableName == null) {
      return null;
    }
    String sql = '';
    List<data_source.DataIndex> dataIndexes = widget.dataIndexController.data;
    if (dataIndexes.isNotEmpty) {
      for (var dataIndex in dataIndexes) {
        String indexName = dataIndex.name!;
        String columnNames = dataIndex.columnNames!;
        sql += 'create index $indexName\n';
        sql += 'on $tableName($columnNames);\n';
      }
    }
    return sql;
  }

  String? _buildSql() {
    String? tableSql = _buildTableSql();
    String? indexSql = _buildIndexSql();
    String? sql;
    if (tableSql != null) {
      sql = tableSql;
      if (indexSql != null) {
        sql += '\n$indexSql';
      }
    }

    return sql;
  }

  Widget _buildDataTableTab(BuildContext context) {
    return Column(
      children: [
        _buildFormInputWidget(context),
        Expanded(
          child: SingleChildScrollView(
            child: CodeTheme(
              data: CodeThemeData(styles: ideaTheme),
              child: CodeField(
                minLines: 15,
                background: Colors.grey.withAlpha(25),
                readOnly: true,
                controller: codeController,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataColumnTab(BuildContext context) {
    return Column(
      children: [
        _buildColumnButtonWidget(context),
        Expanded(child: _buildDataColumnsWidget(context))
      ],
    );
  }

  Widget _buildDataIndexesWidget(BuildContext context) {
    return Obx(() {
      final List<TileData> tiles = [];
      for (int i = 0; i < widget.dataIndexController.data.length; ++i) {
        DataIndex dataIndex = widget.dataIndexController.data[i];
        String titleTail = '';
        if (dataIndex.isUnique != null && dataIndex.isUnique!) {
          titleTail = 'Unique';
        }
        tiles.add(TileData(
            prefix: Icon(
              Icons.content_paste_search,
              color: myself.primary,
            ),
            title: dataIndex.name ?? '',
            titleTail: titleTail,
            subtitle: dataIndex.columnNames ?? '',
            selected: widget.dataIndexController.currentIndex.value == i
                ? true
                : false,
            onTap: (int index, String label, {String? subtitle}) {
              widget.dataIndexController.currentIndex.value = index;
            }));
      }

      return DataListView(
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            return tiles[index];
          });
    });
  }

  Widget _buildDataIndexTab(BuildContext context) {
    return Column(
      children: [
        _buildIndexButtonWidget(context),
        Expanded(child: _buildDataIndexesWidget(context))
      ],
    );
  }

  Widget _buildDataTableTabContainer(BuildContext context) {
    final tabContainer = TabContainer(
      controller: _tabController,
      borderRadius: BorderRadius.circular(8),
      tabBorderRadius: BorderRadius.circular(8),
      color: Colors.white.withAlpha(128),
      curve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        animation = CurvedAnimation(curve: Curves.easeIn, parent: animation);
        return SlideTransition(
          position: Tween(
            begin: const Offset(0.2, 0.0),
            end: const Offset(0.0, 0.0),
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      selectedTextStyle: TextStyle(
        color: myself.primary,
        fontSize: 15.0,
        fontWeight: FontWeight.w900,
      ),
      unselectedTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13.0,
      ),
      tabs: [
        Text(AppLocalizations.t('Table')),
        Text(AppLocalizations.t('Column')),
        Text(AppLocalizations.t('Index'))
      ],
      children: [
        _buildDataTableTab(context),
        _buildDataColumnTab(context),
        _buildDataIndexTab(context),
      ],
    );

    return SizedBox(
        width: appDataProvider.secondaryBodyWidth, child: tabContainer);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: widget.title,
        withLeading: true,
        child: _buildDataTableTabContainer(context));
  }

  @override
  void dispose() {
    _tabController.dispose();
    formInputController?.dispose();
    super.dispose();
  }
}
