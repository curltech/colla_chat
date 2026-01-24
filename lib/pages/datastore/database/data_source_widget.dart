import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_column_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_index_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
import 'package:colla_chat/pages/datastore/database/data_source_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart'
    as data_source;
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/pages/datastore/database/data_table_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/query_console_editor_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/tree_view.dart';
import 'package:flutter/material.dart';

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
    dataSourceController.init();
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
  void _onTap(BuildContext context, ExplorableNode node) {
    DataSourceNode? dataSourceNode;
    DataTableNode? dataTableNode;
    if (node is DataSourceNode) {
      dataSourceNode = node;
    } else if (node is DataTableNode) {
      dataSourceNode = node.parent?.parent as DataSourceNode;
      dataTableNode = node;
    } else if (node is DataColumnNode || node is DataIndexNode) {
      dataSourceNode = node.parent?.parent?.parent?.parent as DataSourceNode;
      dataTableNode = node.parent?.parent as DataTableNode;
    } else if (node is FolderNode) {
      String? name = node.value.name;
      if (name == 'tables') {
        dataSourceNode = node.parent as DataSourceNode;
      } else {
        dataSourceNode = node.parent?.parent?.parent as DataSourceNode;
      }
    }

    dataSourceController.current = dataSourceNode;
    dataSourceController.setCurrentDataTableNode(current: dataTableNode);
    if (node is DataColumnNode) {
      dataSourceController.setCurrentDataColumnNode(node);
    }
    if (node is DataIndexNode) {
      dataSourceController.setCurrentDataIndexNode(node);
    }
  }

  /// 长按表示进一步的操作
  Future<void> _onLongPress(BuildContext context, ExplorableNode node) async {
    _onTap(context, node);
    String? name = node.value.name;
    List<ActionData> popActionData = [];
    if (node is FolderNode &&
        (name == 'tables' || name == 'columns' || name == 'indexes')) {
      popActionData.add(ActionData(
          label: 'New',
          tooltip: 'New',
          icon: Icon(
            Icons.add,
            color: myself.primary,
          )));
    }
    if (node is DataTableNode ||
        node is DataColumnNode ||
        node is DataIndexNode) {
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
    }
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
  void _onToggleNodeExpansion(BuildContext context, ExplorableNode node) {
    if (node is FolderNode) {
      String name = node.value.name;
      DataSourceNode? dataSourceNode = dataSourceController.current;
      if (dataSourceNode == null) {
        return;
      }
      if (name == 'columns') {
        DataTableNode dataTableNode = node.parent as DataTableNode;
        if (node.children.isEmpty) {
          dataSourceController.updateColumnNodes(
            dataSourceNode: dataSourceNode,
            dataTableNode: dataTableNode,
          );
        }
      } else if (name == 'indexes') {
        DataTableNode dataTableNode = node.parent as DataTableNode;
        if (node.children.isEmpty) {
          dataSourceController.updateIndexNodes(
            dataSourceNode: dataSourceNode,
            dataTableNode: dataTableNode,
          );
        }
      }
    }
  }

  void _addDataSource(String sourceType) {
    DataSource dataSource = DataSource('', sourceType: sourceType);
    DataSourceNode dataSourceNode = DataSourceNode(dataSource);
    dataSourceController.current = dataSourceNode;
    indexWidgetProvider.push('data_source_edit');
  }

  /// 增加表，列或索引，节点没有变化，进入数据编辑页面
  void _add(ExplorableNode node) {
    Explorable? explorable = node.value;
    if (explorable is Folder) {
      if ('tables' == node.value.name) {
        data_source.DataTable dataTable = data_source.DataTable('');
        data_source.DataSource? dataSource =
            dataSourceController.current as data_source.DataSource?;
        if (dataSource == null) {
          return;
        }
        dataSourceController.addDataTable(dataTable);
        indexWidgetProvider.push('data_table_edit');
      } else if ('columns' == node.value.name) {
        data_source.DataColumn dataColumn = data_source.DataColumn('');
        dataSourceController.addDataColumn(dataColumn);
        indexWidgetProvider.push('data_column_edit');
      } else if ('indexes' == node.value.name) {
        data_source.DataIndex dataIndex = data_source.DataIndex('');
        dataSourceController.addDataIndex(dataIndex);
        indexWidgetProvider.push('data_index_edit');
      }
    }
  }

  /// 删除节点，同时删除数据
  Future<void> _delete(ExplorableNode node) async {
    if (node is DataSourceNode) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm delete selected data source node?');
      if (confirm != null && confirm) {
        dataSourceController.deleteDataSource(dataSourceNode: node);
      }
    } else if (node is DataTableNode) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm delete selected data table node?');
      if (confirm != null && confirm) {
        DataSource? dataSource =
            dataSourceController.current as data_source.DataSource?;
        if (dataSource == null) {
          return;
        }
        dataSourceController.removeDataTableNode(dataTableNode: node);
      }
    } else if (node is DataColumnNode) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm delete selected data column node?');
      if (confirm != null && confirm) {
        DataSource? dataSource =
            dataSourceController.current as data_source.DataSource?;
        if (dataSource == null) {
          return;
        }
        var dataTable = dataSourceController.getDataTableNode();
        if (dataTable == null) {
          return;
        }
        dataSourceController.removeDataColumnNode(node);
      }
    } else if (node is DataIndexNode) {
      bool? confirm = await DialogUtil.confirm(
          content: 'Do you confirm delete selected data index node?');
      if (confirm != null && confirm) {
        DataSource? dataSource =
            dataSourceController.current as data_source.DataSource?;
        if (dataSource == null) {
          return;
        }
        var dataTable = dataSourceController.getDataTableNode();
        if (dataTable == null) {
          return;
        }
        dataSourceController.removeDataIndexNode(node);
      }
    }
  }

  Future<void> _updateDataColumns() async {
    List<DataColumnNode>? dataColumnNodes =
        dataSourceController.getDataColumnNodes();
    if (dataColumnNodes == null) {
      return;
    }
    List<data_source.DataColumn>? dataColumns = [];
    for (DataColumnNode dataColumnNode in dataColumnNodes) {
      dataColumns.add(dataColumnNode.value as data_source.DataColumn);
    }
    dataTableColumnController.replaceAll(dataColumns);
  }

  Future<void> _updateDataIndexes() async {
    List<DataIndexNode>? dataIndexNodes =
        dataSourceController.getDataIndexNodes();
    if (dataIndexNodes == null) {
      return;
    }
    List<data_source.DataIndex>? dataIndexes = [];
    for (DataIndexNode dataIndexNode in dataIndexNodes) {
      dataIndexes.add(dataIndexNode.value as data_source.DataIndex);
    }
    dataTableIndexController.replaceAll(dataIndexes);
  }

  void _edit(ExplorableNode node) {
    Explorable? explorable = node.value;
    if (explorable is DataSource) {
      indexWidgetProvider.push('data_source_edit');
    } else if (explorable is data_source.DataTable) {
      _updateDataColumns();
      _updateDataIndexes();
      indexWidgetProvider.push('data_table_edit');
    } else if (explorable is data_source.DataColumn) {
      indexWidgetProvider.push('data_column_edit');
    } else if (explorable is data_source.DataIndex) {
      indexWidgetProvider.push('data_index_edit');
    }
  }

  void _query(ExplorableNode node) {
    Explorable? explorable = node.value;
    if (explorable is data_source.DataSource) {
      dataSourceController.current = node as data_source.DataSourceNode?;
      indexWidgetProvider.push('query_console_editor');
    } else if (explorable is data_source.DataTable) {
      codeController.text = 'select * from ${node.value.name}';
      indexWidgetProvider.push('query_console_editor');
    }
  }

  Future<void> _onPopAction(
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
    return TreeView(
      treeViewController: dataSourceController.treeViewController!,
      onTap: (ExplorableNode node) {
        _onTap(context, node);
      },
      toggleNodeExpansion: (ExplorableNode node) {
        _onToggleNodeExpansion(context, node);
      },
      onLongPress: (ExplorableNode node) {
        _onLongPress(context, node);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title,
        withLeading: true,
        child: Column(children: [
          _buildDataSourceButtonWidget(context),
          Expanded(child: _buildTreeView(context)),
        ]));
  }
}
