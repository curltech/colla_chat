import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart'
    as data_source;
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
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

class DataTableEditWidget extends StatefulWidget with TileDataMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_table_edit';

  @override
  IconData get iconData => Icons.table_view_outlined;

  @override
  String get title => 'DataTableEdit';

  DataTableEditWidget({super.key});

  @override
  State<StatefulWidget> createState() => _DataTableEditWidgetState();
}

class _DataTableEditWidgetState extends State<DataTableEditWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
  }

  _buildDataColumns() async {
    DataListController<data_source.DataColumn>? dataColumnController =
        dataSourceController.getDataColumnController();
    dataColumnController ??= await dataSourceController.updateColumnNodes();
  }

  _buildDataIndexes() async {
    DataListController<data_source.DataIndex>? dataIndexController =
        dataSourceController.getDataIndexController();
    dataIndexController ??= await dataSourceController.updateIndexNodes();
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
      data_source.DataTable? dataTable = dataSourceController.getDataTable();
      if (dataTable?.name == null) {
        return Container();
      }
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
                String? sql = createTableAndIndex();

                if (sql != null) {
                  codeController.fullText = sql;
                }
              }),
          FormButton(
              label: 'Execute',
              onTap: (Map<String, dynamic> values) async {
                await _onOk(values);
                try {
                  String? sql = createTableAndIndex(mock: false);
                  if (sql != null) {
                    codeController.fullText = sql;
                  }
                } catch (e) {
                  DialogUtil.error(
                      content: AppLocalizations.t('execute sql failure:$e'));
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
    data_source.DataTable? dataTable = dataSourceController.getDataTable();
    if (dataTable == null) {
      dataTable = data_source.DataTable();
      dataTable.name = current.name;
      dataTable.comment = current.comment;
      dataSourceController.addDataTable(dataTable);
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

    return Obx(() {
      _buildDataColumns();
      DataListController<data_source.DataColumn>? dataColumnController =
          dataSourceController.getDataColumnController();
      if (dataColumnController == null) {
        return nilBox;
      }

      return BindingDataTable2<data_source.DataColumn>(
        key: UniqueKey(),
        showCheckboxColumn: true,
        horizontalMargin: 15.0,
        columnSpacing: 0.0,
        platformDataColumns: platformDataColumns,
        controller: dataColumnController,
        fixedLeftColumns: 0,
      );
    });
  }

  String? _getCheckedColumnNames() {
    var dataColumnController = dataSourceController.getDataColumnController();
    if (dataColumnController == null) {
      return null;
    }
    List<data_source.DataColumn> dataColumns = dataColumnController.checked;
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
    data_source.DataTable? dataTable = dataSourceController.getDataTable();
    if (dataTable == null) {
      return Container();
    }
    return OverflowBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            tooltip: AppLocalizations.t('New column'),
            onPressed: () {
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              DataListController<data_source.DataColumn>? dataColumnController =
                  dataSourceController.getDataColumnController();
              data_source.DataColumn dataColumn = data_source.DataColumn();
              dataColumnController?.add(dataColumn);
              indexWidgetProvider.push('data_column_edit');
            },
            icon: Icon(
              Icons.add,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Delete column'),
            onPressed: () {
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              DataListController<data_source.DataColumn>? dataColumnController =
                  dataSourceController.getDataColumnController();
              List<data_source.DataColumn>? dataColumns =
                  dataColumnController?.checked;
              if (dataColumns == null || dataColumns.isEmpty) {
                return;
              }
              for (data_source.DataColumn dataColumn in dataColumns) {
                dataColumnController?.data.remove(dataColumn);
                dataSourceController.current?.dataStore?.run(Sql(
                    'alter table ${dataTable.name} drop column ${dataColumn.name};'));
              }
            },
            icon: Icon(Icons.remove, color: myself.primary)),
        IconButton(
            tooltip: AppLocalizations.t('Edit column'),
            onPressed: () {
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              indexWidgetProvider.push('data_column_edit');
            },
            icon: Icon(Icons.edit, color: myself.primary)),
      ],
    );
  }

  Widget _buildIndexButtonWidget(BuildContext context) {
    data_source.DataTable? dataTable = dataSourceController.getDataTable();
    if (dataTable == null) {
      return Container();
    }
    return OverflowBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            tooltip: AppLocalizations.t('New index'),
            onPressed: () {
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
              dataIndex.name =
                  '${dataTable.name}_${columnNames.replaceAll(',', '_')}_index';
              dataIndex.columnNames = columnNames;
              DataListController<data_source.DataColumn>? dataColumnController =
                  dataSourceController.getDataColumnController();
              dataColumnController?.setCheckAll(false);
              DataListController<data_source.DataIndex>? dataIndexController =
                  dataSourceController.getDataIndexController();
              dataIndexController?.add(dataIndex);
              indexWidgetProvider.push('data_index_edit');
            },
            icon: Icon(
              Icons.add,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Delete index'),
            onPressed: () {
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              DataListController<data_source.DataIndex>? dataIndexController =
                  dataSourceController.getDataIndexController();
              List<data_source.DataIndex>? dataIndexes =
                  dataIndexController?.checked;
              if (dataIndexes == null || dataIndexes.isEmpty) {
                return;
              }
              for (data_source.DataIndex dataIndex in dataIndexes) {
                dataIndexController?.remove(dataIndex);
                dataSourceController.current?.dataStore
                    ?.run(Sql('drop index ${dataIndex.name}'));
              }
            },
            icon: Icon(Icons.remove, color: myself.primary)),
        IconButton(
            tooltip: AppLocalizations.t('Edit index'),
            onPressed: () {
              if (dataTable.name == null) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }

              indexWidgetProvider.push('data_index_edit');
            },
            icon: Icon(Icons.edit, color: myself.primary)),
      ],
    );
  }

  final codeController = CodeController(
    language: sql,
  );

  String? createTableAndIndex({bool mock = true}) {
    String? tableSql = dataSourceController.createDataTable(mock: mock);
    String? indexSql = dataSourceController.createDataIndex(mock: mock);
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
      _buildDataIndexes();
      final List<TileData> tiles = [];
      DataListController<data_source.DataIndex>? dataIndexController =
          dataSourceController.getDataIndexController();
      if (dataIndexController == null) {
        return nilBox;
      }
      for (int i = 0; i < dataIndexController.data.length; ++i) {
        DataIndex dataIndex = dataIndexController.data[i];
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
            selected:
                dataIndexController.currentIndex.value == i ? true : false,
            onTap: (int index, String label, {String? subtitle}) {
              dataIndexController.currentIndex.value = index;
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
      color: Colors.white.withAlpha(0),
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
