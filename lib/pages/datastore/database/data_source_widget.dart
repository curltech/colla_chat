import 'package:animated_tree_view/animated_tree_view.dart' as animated;
import 'package:checkable_treeview/checkable_treeview.dart' as checkable;
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

  /// 单击节点，设置当前数据源和数据表
  void _onTap(BuildContext context, AnimatedExplorableNode node) {
    dataSourceController.currentNode.value = node;
    animated.TreeNode? dataSourceNode;
    animated.TreeNode? dataTableNode;
    if (node is DataSourceNode) {
      dataSourceNode = node;
    } else if (node is DataTableNode) {
      dataSourceNode = node.parent?.parent as DataSourceNode;
    } else if (node is DataColumnNode || node is DataIndexNode) {
      dataTableNode = node.parent as DataTableNode;
      dataSourceNode = node.parent?.parent?.parent?.parent as DataSourceNode;
    } else if (node is FolderNode) {
      String? name = node.data?.name;
      if (name == 'tables') {
        dataSourceNode = node.parent as DataSourceNode;
      } else {
        dataSourceNode = node.parent?.parent?.parent as DataSourceNode;
      }
    }
    DataSource? dataSource = dataSourceNode?.data;
    dataSourceController.current = dataSource;
    if (dataSource != null) {
      var dataTableController =
          dataSourceController.dataTableControllers[dataSource.name];
      if (dataTableController != null) {
        dataTableController.current = dataTableNode?.data;
      }
    }
  }

  /// 长按表示进一步的操作
  Future<void> _onLongPress(
      BuildContext context, AnimatedExplorableNode node) async {
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

  /// 单击时加载列或索引
  void _onItemTap(BuildContext context, AnimatedExplorableNode node) {
    if (node is FolderNode) {
      String? tableName = (node.parent as animated.TreeNode).data.name;
      String? name = node.data?.name;
      DataSource? dataSource = dataSourceController.current;
      if (dataSource == null) {
        return;
      }
      if (name == 'columns') {
        if (node.length == 0) {
          dataSourceController.updateColumnNodes(
              dataSource: dataSource, tableName: tableName, node);
        }
      } else if (name == 'indexes') {
        if (node.length == 0) {
          dataSourceController.updateIndexNodes(
              dataSource: dataSource, tableName: tableName, node);
        }
      }
    }
  }

  void _addDataSource(String sourceType) {
    DataSource dataSource = DataSource(sourceType: sourceType);
    DataSourceNode dataSourceNode = DataSourceNode(data: dataSource);
    dataSourceController.current = dataSourceNode.data;
    indexWidgetProvider.push('data_source_edit');
  }

  /// 增加表，列或索引，节点没有变化，进入数据编辑页面
  void _add(AnimatedExplorableNode node) {
    if (node is FolderNode) {
      if ('tables' == node.data!.name) {
        data_source.DataTable dataTable = data_source.DataTable();
        DataTableNode dataTableNode = DataTableNode(data: dataTable);
        data_source.DataSource? dataSource = dataSourceController.current;
        if (dataSource == null) {
          return;
        }
        DataTableController? dataTableController =
            dataSourceController.dataTableControllers[dataSource.name];
        dataTableController!.add(dataTableNode.data!);
        indexWidgetProvider.push('data_table_edit');
      } else if ('columns' == node.data!.name) {
        data_source.DataColumn dataColumn = data_source.DataColumn();
        dataSourceController.setCurrentDataColumn(dataColumn);
        indexWidgetProvider.push('data_column_edit');
      } else if ('indexes' == node.data!.name) {
        data_source.DataIndex dataIndex = data_source.DataIndex();
        DataIndexNode dataIndexNode = DataIndexNode(data: dataIndex);
        dataSourceController.setCurrentDataIndex(dataIndex);
        indexWidgetProvider.push('data_index_edit');
      }
    }
  }

  /// 删除节点，同时删除数据
  Future<void> _delete(AnimatedExplorableNode node) async {
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
        DataSource? dataSource = dataSourceController.current;
        if (dataSource == null) {
          return;
        }
        var dataTableController =
            dataSourceController.dataTableControllers[dataSource.name];
        dataTableController?.remove(node.data!);
        node.delete();
        dataSourceController.current?.dataStore
            ?.run(Sql('drop table ${node.data?.name}'));
      }
    } else if (node is DataColumnNode) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm delete selected data column node?');
      if (confirm != null && confirm) {
        DataSource? dataSource = dataSourceController.current;
        if (dataSource == null) {
          return;
        }
        var dataTable = dataSourceController.getDataTable();
        if (dataTable == null) {
          return;
        }
        var dataColumnController = dataSourceController.getDataColumnController(
            dataSource: dataSource, tableName: dataTable.name);
        dataColumnController?.remove(node.data!);
        node.delete();
        dataSourceController.current?.dataStore?.run(Sql(
            'alter table ${dataTable.name} drop column ${node.data?.name};'));
      }
    } else if (node is DataIndexNode) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm delete selected data index node?');
      if (confirm != null && confirm) {
        DataSource? dataSource = dataSourceController.current;
        if (dataSource == null) {
          return;
        }
        var dataTable = dataSourceController.getDataTable();
        if (dataTable == null) {
          return;
        }
        var dataIndexController = dataSourceController.getDataIndexController(
            dataSource: dataSource, tableName: dataTable.name);
        dataIndexController?.remove(node.data!);
        node.delete();
        dataSourceController.current?.dataStore
            ?.run(Sql('drop index ${node.data?.name}'));
      }
    }
  }

  void _edit(AnimatedExplorableNode node) {
    if (node is DataSourceNode) {
      indexWidgetProvider.push('data_source_edit');
    } else if (node is DataTableNode) {
      indexWidgetProvider.push('data_table_edit');
    } else if (node is DataColumnNode) {
      indexWidgetProvider.push('data_column_edit');
    } else if (node is DataIndexNode) {
      indexWidgetProvider.push('data_index_edit');
    }
  }

  void _query(AnimatedExplorableNode node) {
    if (node is data_source.DataSourceNode) {
      dataSourceController.current = node.data;
      indexWidgetProvider.push('query_console_editor');
    } else if (node is DataTableNode) {
      codeController.text = 'select * from ${node.data!.name}';
      indexWidgetProvider.push('query_console_editor');
    }
  }

  _onPopAction(BuildContext context, AnimatedExplorableNode node, int index,
      String label,
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

  Widget _buildAnimatedTreeView(BuildContext context) {
    return animated.TreeView.simpleTyped<Explorable, AnimatedExplorableNode>(
        tree: dataSourceController.animatedRoot,
        showRootNode: false,
        expansionBehavior: animated.ExpansionBehavior.none,
        expansionIndicatorBuilder: (context, node) {
          return animated.ChevronIndicator.rightDown(
            tree: node,
            alignment: Alignment.centerLeft,
            color: myself.primary,
          );
        },
        indentation: animated.Indentation(
          width: 12,
          color: myself.primary,
          style: animated.IndentStyle.none,
          thickness: 1,
          offset: Offset(12, 0),
        ),
        onTreeReady: (controller) {
          dataSourceController.treeViewController = controller;
        },
        builder: (context, AnimatedExplorableNode node) {
          return Obx(() {
            bool selected = false;
            if (node is DataSourceNode) {
              selected = dataSourceController.current == node.data;
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
        onItemTap: (AnimatedExplorableNode node) {
          _onItemTap(context, node);
        });
  }

  Widget _buildCheckableTreeView(BuildContext context) {
    return checkable.TreeView<Explorable>(
      key: dataSourceController.checkableTreeViewKey,
      nodes: dataSourceController.checkableRoot,
      onSelectionChanged: (selectedValues) {
        print('Selected values: $selectedValues');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildDataSourceButtonWidget(context),
      Expanded(child: _buildAnimatedTreeView(context)),
    ]);
  }
}

extension on AnimatedExplorableNode {
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
