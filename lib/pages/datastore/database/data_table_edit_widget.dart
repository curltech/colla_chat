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
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
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

DataListController<data_source.DataColumn> dataTableColumnController =
    DataListController<data_source.DataColumn>(data: []);

DataListController<data_source.DataIndex> dataTableIndexController =
    DataListController<data_source.DataIndex>(data: []);

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

  /// DataTableNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    return Obx(() {
      data_source.DataTableNode? dataTableNode =
          dataSourceController.getDataTableNode();
      if (dataTableNode == null) {
        return Container();
      }
      List<PlatformDataField> dataSourceDataFields =
          buildDataTableDataFields(SourceType.sqlite.name);
      formInputController = FormInputController(dataSourceDataFields);

      formInputController?.setValues(JsonUtil.toJson(dataTableNode.value));
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
    data_source.DataTableNode? dataTableNode =
        dataSourceController.getDataTableNode();
    if (dataTableNode == null) {
      data_source.DataTable dataTable = data_source.DataTable(current.name);
      dataSourceController.addDataTable(dataTable);
    } else {
      dataTableNode.value.name = current.name;
      dataTableNode.value.comment = current.comment;
    }

    DialogUtil.info(content: 'Successfully update dataTable:${current.name}');

    return current;
  }

  Widget _buildDataColumnsWidget(BuildContext context) {
    final List<PlatformDataColumn> platformDataColumns = [];
    platformDataColumns.add(PlatformDataColumn(
      label: 'Name',
      name: 'name',
      dataType: DataType.string,
    ));
    platformDataColumns.add(PlatformDataColumn(
      label: 'DataType',
      name: 'dataType',
      dataType: DataType.string,
    ));
    platformDataColumns.add(PlatformDataColumn(
      label: 'isKey',
      name: 'isKey',
      dataType: DataType.bool,
      align: Alignment.centerRight,
    ));

    return BindingTrinaDataGrid<data_source.DataColumn>(
      key: UniqueKey(),
      showCheckboxColumn: true,
      horizontalMargin: 15.0,
      columnSpacing: 0.0,
      platformDataColumns: platformDataColumns,
      controller: dataTableColumnController,
      fixedLeftColumns: 0,
    );
  }

  String? _getSelectedColumnNames() {
    List<data_source.DataColumn> dataColumns =
        dataTableColumnController.selected;
    if (dataColumns.isEmpty) {
      return null;
    }
    String names = '';
    for (int i = 0; i < dataColumns.length; ++i) {
      data_source.DataColumn dataColumn = dataColumns[i];
      if (i > 0) {
        names += ',';
      }
      names += dataColumn.name;
    }

    return names;
  }

  Widget _buildColumnButtonWidget(BuildContext context) {
    data_source.DataTableNode? dataTableNode =
        dataSourceController.getDataTableNode();
    if (dataTableNode == null) {
      return Container();
    }
    return OverflowBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            tooltip: AppLocalizations.t('New column'),
            onPressed: () {
              if (dataTableNode.value.name.isEmpty) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              data_source.DataColumn dataColumn = data_source.DataColumn('');
              dataTableColumnController.add(dataColumn);
              indexWidgetProvider.push('data_column_edit');
            },
            icon: Icon(
              Icons.add,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Delete column'),
            onPressed: () {
              if (dataTableNode.value.name.isEmpty) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              List<data_source.DataColumn> dataColumns =
                  dataTableColumnController.selected;
              if (dataColumns.isEmpty) {
                return;
              }
              for (data_source.DataColumn dataColumn in dataColumns) {
                dataSourceController
                    .removeDataColumnNode(DataColumnNode(dataColumn));
              }
            },
            icon: Icon(Icons.remove, color: myself.primary)),
        IconButton(
            tooltip: AppLocalizations.t('Edit column'),
            onPressed: () {
              if (dataTableNode.value.name.isEmpty) {
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
    data_source.DataTableNode? dataTableNode =
        dataSourceController.getDataTableNode();
    if (dataTableNode == null) {
      return Container();
    }
    return OverflowBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            tooltip: AppLocalizations.t('New index'),
            onPressed: () {
              if (dataTableNode.value.name.isEmpty) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              String? columnNames = _getSelectedColumnNames();
              if (columnNames == null) {
                DialogUtil.error(content: 'Please choose column of index');
                return;
              }
              data_source.DataIndex dataIndex = data_source.DataIndex('');
              dataIndex.name =
                  '${dataTableNode.value.name}_${columnNames.replaceAll(',', '_')}_index';
              dataIndex.columnNames = columnNames;
              dataSourceController.addDataIndex(dataIndex);
              dataTableColumnController.unselectAll();
              indexWidgetProvider.push('data_index_edit');
            },
            icon: Icon(
              Icons.add,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Delete index'),
            onPressed: () {
              if (dataTableNode.value.name.isEmpty) {
                DialogUtil.error(content: 'Please input table name');
                return;
              }
              List<data_source.DataIndex>? dataIndexes =
                  dataTableIndexController.selected;
              if (dataIndexes.isEmpty) {
                return;
              }
              for (data_source.DataIndex dataIndex in dataIndexes) {
                dataSourceController
                    .removeDataIndexNode(DataIndexNode(dataIndex));
              }
            },
            icon: Icon(Icons.remove, color: myself.primary)),
        IconButton(
            tooltip: AppLocalizations.t('Edit index'),
            onPressed: () {
              if (dataTableNode.value.name.isEmpty) {
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
      final List<TileData> tiles = [];
      for (int i = 0; i < dataTableIndexController.data.length; ++i) {
        DataIndex dataIndex = dataTableIndexController.data[i];
        String titleTail = '';
        if (dataIndex.isUnique != null && dataIndex.isUnique!) {
          titleTail = 'Unique';
        }
        tiles.add(TileData(
            prefix: Icon(
              Icons.content_paste_search,
              color: myself.primary,
            ),
            title: dataIndex.name,
            titleTail: titleTail,
            subtitle: dataIndex.columnNames ?? '',
            selected:
                dataTableIndexController.currentIndex.value == i ? true : false,
            onTap: (int index, String label, {String? subtitle}) {
              dataTableIndexController.currentIndex.value = index;
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
