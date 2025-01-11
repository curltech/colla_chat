import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_column_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
import 'package:colla_chat/pages/datastore/database/data_source_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/pages/datastore/database/data_table_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/query_console_editor_widget.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_node.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart'
    as data_source;

/// 数据源管理功能主页面，带有路由回调函数
class DataSourceWidget extends StatelessWidget with TileDataMixin {
  final DataSourceEditWidget dataSourceEditWidget = DataSourceEditWidget();
  final DataTableEditWidget dataTableEditWidget = DataTableEditWidget();
  final DataColumnEditWidget dataColumnEditWidget = DataColumnEditWidget();
  final QueryConsoleEditorWidget queryConsoleEditorWidget =
      QueryConsoleEditorWidget();

  DataSourceWidget({super.key}) {
    indexWidgetProvider.define(dataSourceEditWidget);
    indexWidgetProvider.define(dataTableEditWidget);
    indexWidgetProvider.define(dataColumnEditWidget);
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

  late final TreeViewController? treeViewController;

  /// 单击表示编辑属性
  void _onTap(BuildContext context, ExplorableNode node) {
    if (node is DataSourceNode) {
      rxDataSourceNode.value = node;
      indexWidgetProvider.push('data_source_edit');
    }
    if (node is DataTableNode) {}
    if (node is DataColumnNode) {}
    if (node is DataIndexNode) {}
  }

  /// 长按表示进一步的操作
  Future<void> _onLongPress(BuildContext context, ExplorableNode node) async {
    List<ActionData> popActionData = [];

    popActionData.add(
        ActionData(label: 'New', tooltip: 'New', icon: const Icon(Icons.add)));
    popActionData.add(ActionData(
        label: 'Delete', tooltip: 'Delete', icon: const Icon(Icons.remove)));
    popActionData.add(ActionData(
        label: 'Edit', tooltip: 'Edit', icon: const Icon(Icons.edit)));
    popActionData.add(ActionData(
        label: 'Edit data',
        tooltip: 'Edit data',
        icon: const Icon(Icons.dataset)));
    if (node is DataSourceNode) {}
    if (node is DataTableNode) {}
    if (node is DataColumnNode) {}
    if (node is DataIndexNode) {}

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

  void _addDataSource(String sourceType) {
    DataSource dataSource = DataSource('', sourceType: sourceType);
    DataSourceNode dataSourceNode = DataSourceNode(data: dataSource);
    rxDataSourceNode.value = dataSourceNode;
    indexWidgetProvider.push('data_source_edit');
  }

  void _add(ExplorableNode node) {
    if (node is FolderNode) {
      if ('tables' == node.data!.name) {
        data_source.DataTable dataTable = data_source.DataTable('');
        DataTableNode dataTableNode = DataTableNode(data: dataTable);
        rxDataTableNode.value = dataTableNode;
        indexWidgetProvider.push('data_table_edit');
      }
      if ('columns' == node.data!.name) {
        data_source.DataColumn dataColumn = data_source.DataColumn('');
        DataColumnNode dataColumnNode = DataColumnNode(data: dataColumn);
        rxDataColumnNode.value = dataColumnNode;
        indexWidgetProvider.push('data_column_edit');
      }
      if ('indexes' == node.data!.name) {}
    }
  }

  _onPopAction(
      BuildContext context, ExplorableNode node, int index, String label,
      {String? value}) async {
    switch (label) {
      case 'Add':
        _add(node);
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      OverflowBar(
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
              onPressed: () {},
              icon: Icon(
                Icons.remove,
                color: myself.primary,
              )),
          IconButton(
              tooltip: AppLocalizations.t('Refresh data source'),
              onPressed: () {},
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
      ),
      Expanded(
          child: TreeView.simpleTyped<Explorable, ExplorableNode>(
              tree: dataSourceController.root,
              showRootNode: false,
              expansionBehavior: ExpansionBehavior.scrollToLastChild,
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
                style: IndentStyle.squareJoint,
                thickness: 2,
                offset: Offset(12, 0),
              ),
              onTreeReady: (controller) {
                treeViewController = controller;
              },
              builder: (context, ExplorableNode node) {
                return Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: ListTile(
                    title: Text(node.data?.name ?? "/"),
                    dense: true,
                    leading: node.icon,
                    minVerticalPadding: 0.0,
                    minTileHeight: 28,
                    selected: dataSourceController.currentNode.value == node,
                    selectedColor: myself.primary,
                    selectedTileColor: myself.secondary,
                    onTap: () {
                      dataSourceController.currentNode.value = node;
                      _onTap(context, node);
                    },
                    onLongPress: () {
                      _onLongPress(context, node);
                    },
                  ),
                );
              },
              onItemTap: (ExplorableNode node) {
                _onTap(context, node);
              })),
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
      return Icon(Icons.view_column_outlined, color: myself.primary);
    }

    if (this is FileNode) {
      final file = data as File;
      if (file.mimeType.startsWith("image")) {
        return Icon(Icons.image, color: myself.primary);
      }
      if (file.mimeType.startsWith("video")) {
        return Icon(Icons.video_file, color: myself.primary);
      }
      return Icon(Icons.file_open_outlined, color: myself.primary);
    }

    if (isExpanded) {
      return Icon(Icons.folder_open, color: myself.primary);
    }
    return Icon(Icons.folder, color: myself.primary);
  }
}
