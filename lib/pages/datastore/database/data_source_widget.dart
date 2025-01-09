import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_node.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 数据源管理功能主页面，带有路由回调函数
class DataSourceWidget extends StatelessWidget with TileDataMixin {
  DataSourceWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_source';

  @override
  IconData get iconData => Icons.dataset_outlined;

  @override
  String get title => 'DataSource';

  TreeViewController? treeViewController;

  /// 单击表示编辑属性
  void _onTap(ExplorableNode node) {}

  /// 长按表示进一步的操作
  void _onLongPress(ExplorableNode node) {}

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      OverflowBar(
        alignment: MainAxisAlignment.start,
        children: [
          IconButton(
              tooltip: AppLocalizations.t('Add data source'),
              onPressed: () {},
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
              onPressed: () {},
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
              builder: (context, ExplorableNode node) => Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: ListTile(
                      title: Text(node.data?.name ?? "/"),
                      dense: true,
                      leading: node.icon,
                      selected: dataSourceController.currentNode.value == node,
                      onTap: () {
                        dataSourceController.currentNode.value = node;
                        _onTap(node);
                      },
                      onLongPress: () {
                        _onLongPress(node);
                      },
                    ),
                  ))),
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

    if (this is TableNode) {
      return Icon(Icons.table_view_outlined, color: myself.primary);
    }

    if (this is ColumnNode) {
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
