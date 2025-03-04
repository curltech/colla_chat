import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_column_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_index_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
import 'package:colla_chat/pages/datastore/database/data_source_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/pages/datastore/database/data_table_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/query_console_editor_widget.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart'
    as data_source;
import 'package:get/get.dart';

/// 数据源管理功能主页面，带有路由回调函数
class DataSourceWidget extends StatelessWidget with TileDataMixin {
  final DataSourceEditWidget dataSourceEditWidget = DataSourceEditWidget();
  final DataTableEditWidget dataTableEditWidget = DataTableEditWidget();
  final DataColumnEditWidget dataColumnEditWidget = DataColumnEditWidget();
  final DataIndexEditWidget dataIndexEditWidget = DataIndexEditWidget();
  final QueryConsoleEditorWidget queryConsoleEditorWidget =
      QueryConsoleEditorWidget();

  DataSourceWidget({super.key}) {
    indexWidgetProvider.define(dataSourceEditWidget);
    indexWidgetProvider.define(dataTableEditWidget);
    indexWidgetProvider.define(dataColumnEditWidget);
    indexWidgetProvider.define(dataIndexEditWidget);
    indexWidgetProvider.define(queryConsoleEditorWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_source';

  @override
  IconData get iconData => Icons.dataset_outlined;

  @override
  String get title => 'DataSource';

  @override
  String? get information => null;

  /// 单击表示编辑属性
  void _onTap(BuildContext context, ExplorableNode node) {
    dataSourceController.currentNode.value = node;
    TreeNode? dataSourceNode;
    if (node is DataSourceNode) {
      dataSourceNode = node;
    } else if (node is DataTableNode) {
      dataSourceNode = node.parent?.parent as DataSourceNode;
    } else if (node is DataColumnNode || node is DataIndexNode) {
      dataSourceNode = node.parent?.parent?.parent?.parent as DataSourceNode;
    } else if (node is FolderNode) {
      String? name = node.data?.name;
      if (name == 'tables') {
        dataSourceNode = node.parent as DataSourceNode;
      } else {
        dataSourceNode = node.parent?.parent?.parent as DataSourceNode;
      }
    }
    dataSourceController.current.value = dataSourceNode?.data;
  }

  /// 长按表示进一步的操作
  Future<void> _onLongPress(BuildContext context, ExplorableNode node) async {
    dataSourceController.currentNode.value = node;
    List<ActionData> popActionData = [];
    popActionData.add(ActionData(
        label: 'New',
        tooltip: 'New',
        icon: Icon(
          Icons.add,
          color: myself.primary,
        )));
    popActionData.add(ActionData(
        label: 'Delete',
        tooltip: 'Delete',
        icon: Icon(
          Icons.remove,
          color: myself.primary,
        )));
    popActionData.add(ActionData(
        label: 'Edit',
        tooltip: 'Edit',
        icon: Icon(
          Icons.edit,
          color: myself.primary,
        )));
    popActionData.add(ActionData(
        label: 'Query',
        tooltip: 'Query',
        icon: Icon(
          Icons.search_outlined,
          color: myself.primary,
        )));

    await MenuUtil.showPopMenu(
      context,
      onPressed: (BuildContext context, int index, String label,
          {String? value}) {
        _onPopAction(context, node, index, label, value: value);
      },
      height: 200,
      width: appDataProvider.secondaryBodyWidth,
      actions: popActionData,
    );
  }

  void _onItemTap(BuildContext context, ExplorableNode node) {
    if (node is FolderNode) {
      String? tableName = (node.parent as TreeNode).data.name;
      String? name = node.data?.name;
      if (name == 'columns') {
        if (node.length == 0) {
          dataSourceController.updateColumnNodes(tableName!, node);
        }
      } else if (name == 'indexes') {
        if (node.length == 0) {
          dataSourceController.updateIndexNodes(tableName!, node);
        }
      }
    }
  }

  void _addDataSource(String sourceType) {
    DataSource dataSource = DataSource(sourceType: sourceType);
    DataSourceNode dataSourceNode = DataSourceNode(data: dataSource);
    rxDataSource.value = dataSourceNode.data;
    indexWidgetProvider.push('data_source_edit');
  }

  void _add(ExplorableNode node) {
    if (node is FolderNode) {
      if ('tables' == node.data!.name) {
        data_source.DataTable dataTable = data_source.DataTable();
        DataTableNode dataTableNode = DataTableNode(data: dataTable);
        rxDataTable.value = dataTableNode.data;
        indexWidgetProvider.push('data_table_edit');
      } else if ('columns' == node.data!.name) {
        data_source.DataColumn dataColumn = data_source.DataColumn();
        DataColumnNode dataColumnNode = DataColumnNode(data: dataColumn);
        rxDataColumn.value = dataColumnNode.data;
        indexWidgetProvider.push('data_column_edit');
      } else if ('indexes' == node.data!.name) {
        data_source.DataIndex dataIndex = data_source.DataIndex();
        DataIndexNode dataIndexNode = DataIndexNode(data: dataIndex);
        rxDataIndex.value = dataIndexNode.data;
        indexWidgetProvider.push('data_index_edit');
      }
    }
  }

  Future<void> _delete(ExplorableNode node) async {
    if (node is DataSourceNode) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm delete selected data source node?');
      if (confirm != null && confirm) {
        dataSourceController.deleteDataSource(node: node);
      }
    } else if (node is DataTableNode) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm delete selected data table node?');
      if (confirm != null && confirm) {
        dataSourceController.current.value?.dataStore
            ?.run(Sql('drop table ${node.data?.name}'));
      }
    } else if (node is DataColumnNode) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm delete selected data column node?');
      if (confirm != null && confirm) {
        TreeNode dataTableNode = node.parent?.parent as TreeNode;
        dataSourceController.current.value?.dataStore?.run(Sql(
            'alter table ${dataTableNode.data.name} drop column ${node.data?.name};'));
      }
    } else if (node is DataIndexNode) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm delete selected data index node?');
      if (confirm != null && confirm) {
        dataSourceController.current.value?.dataStore
            ?.run(Sql('drop index ${node.data?.name}'));
      }
    }
  }

  void _edit(ExplorableNode node) {
    if (node is DataSourceNode) {
      rxDataSource.value = node.data;
      indexWidgetProvider.push('data_source_edit');
    } else if (node is DataTableNode) {
      rxDataTable.value = node.data;
      indexWidgetProvider.push('data_table_edit');
    } else if (node is DataColumnNode) {
      rxDataColumn.value = node.data;
      indexWidgetProvider.push('data_column_edit');
    } else if (node is DataIndexNode) {
      rxDataIndex.value = node.data;
      indexWidgetProvider.push('data_index_edit');
    }
  }

  void _query(ExplorableNode node) {
    if (node is data_source.DataSourceNode) {
      dataSourceController.current.value = node.data;
      indexWidgetProvider.push('query_console_editor');
    } else if (node is DataTableNode) {
      rxDataTable.value = node.data;
      codeController.text = 'select * from ${rxDataTable.value!.name}';
      indexWidgetProvider.push('query_console_editor');
    }
  }

  _onPopAction(
      BuildContext context, ExplorableNode node, int index, String label,
      {String? value}) async {
    switch (label) {
      case 'New':
        _add(node);
        break;
      case 'Delete':
        _delete(node);
        break;
      case 'Edit':
        _edit(node);
        break;
      case 'Query':
        _query(node);
        break;
      default:
    }
  }

  Widget _buildDataSourceButtonWidget(BuildContext context) {
    return OverflowBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            tooltip: AppLocalizations.t('Add data source'),
            onPressed: () {
              _addDataSource(SourceType.sqlite.name);
            },
            icon: Icon(
              Icons.add,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Delete data source'),
            onPressed: () async {
              bool? confirm = await DialogUtil.confirm(
                  content: 'Do you confirm delete current data source node?');
              if (confirm != null && confirm) {
                dataSourceController.deleteDataSource();
              }
            },
            icon: Icon(
              Icons.remove,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Refresh data source'),
            onPressed: () async {
              await dataSourceController.init();
            },
            icon: Icon(
              Icons.refresh_outlined,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Query console'),
            onPressed: () {
              indexWidgetProvider.push('query_console_editor');
            },
            icon: Icon(
              Icons.terminal_outlined,
              color: myself.primary,
            )),
      ],
    );
  }

  Widget _buildTreeView(BuildContext context) {
    return TreeView.simpleTyped<Explorable, ExplorableNode>(
        tree: dataSourceController.root,
        showRootNode: false,
        expansionBehavior: ExpansionBehavior.none,
        expansionIndicatorBuilder: (context, node) {
          return ChevronIndicator.rightDown(
            tree: node,
            alignment: Alignment.centerLeft,
            color: myself.primary,
          );
        },
        indentation: Indentation(
          width: 12,
          color: myself.primary,
          style: IndentStyle.none,
          thickness: 1,
          offset: Offset(12, 0),
        ),
        onTreeReady: (controller) {
          dataSourceController.treeViewController = controller;
        },
        builder: (context, ExplorableNode node) {
          return Obx(() {
            bool selected = false;
            if (node is DataSourceNode) {
              selected = dataSourceController.current.value == node.data;
            }
            if (!selected) {
              selected = dataSourceController.currentNode.value == node;
            }
            TileData tileData = TileData(
              title: node.data?.name ?? "/",
              titleTail: node is DataColumnNode
                  ? node.data?.dataType ?? ""
                  : node.length.toString(),
              dense: true,
              prefix: node.icon,
              selected: selected,
              onTap: (int index, String label, {String? subtitle}) {
                _onTap(context, node);
                _onItemTap(context, node);
              },
              onLongPress: (int index, String label, {String? subtitle}) {
                _onLongPress(context, node);
              },
            );
            return Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: DataListTile(
                tileData: tileData,
                minVerticalPadding: 0.0,
              ),
            );
          });
        },
        onItemTap: (ExplorableNode node) {
          _onItemTap(context, node);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildDataSourceButtonWidget(context),
      Expanded(child: _buildTreeView(context)),
    ]);
  }
}

extension on ExplorableNode {
  Widget get icon {
    if (isRoot) {
      return Icon(
        Icons.data_object,
        color: myself.primary,
      );
    }

    if (this is FolderNode) {
      if (isExpanded) {
        return Icon(Icons.folder_open, color: myself.primary);
      }
      return Icon(Icons.folder, color: myself.primary);
    }

    if (this is DataSourceNode) {
      final dataSource = data as DataSource;
      if (dataSource.sourceType == SourceType.sqlite.name) {
        return DataSource.sqliteImage;
      } else if (dataSource.sourceType == SourceType.postgres.name) {
        return DataSource.postgresImage;
      }
      return DataSource.sqliteImage;
    }

    if (this is DataTableNode) {
      return Icon(Icons.table_view_outlined, color: myself.primary);
    }

    if (this is DataColumnNode) {
      final dataColumn = data as data_source.DataColumn;
      if (dataColumn.isKey != null && dataColumn.isKey!) {
        return Icon(Icons.key, color: myself.primary);
      }
      return Icon(Icons.view_column_outlined, color: myself.primary);
    }

    if (this is DataIndexNode) {
      return Icon(Icons.content_paste_search, color: myself.primary);
    }

    if (isExpanded) {
      return Icon(Icons.folder_open, color: myself.primary);
    }
    return Icon(Icons.folder, color: myself.primary);
  }
}
