import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_node.dart';
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

  @override
  Widget build(BuildContext context) {
    return TreeView.simpleTyped<Explorable, ExplorableNode>(
        tree: dataSourceController.root,
        showRootNode: false,
        expansionBehavior: ExpansionBehavior.scrollToLastChild,
        expansionIndicatorBuilder: (context, node) {
          if (node.isRoot) {
            return PlusMinusIndicator(
              tree: node,
              alignment: Alignment.centerLeft,
              color: Colors.grey[700],
            );
          }

          return ChevronIndicator.rightDown(
            tree: node,
            alignment: Alignment.centerLeft,
            color: Colors.grey[700],
          );
        },
        indentation: const Indentation(),
        builder: (context, ExplorableNode node) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ListTile(
                title: Text(node.data?.name ?? "N/A"),
                dense: true,
                // trailing: Text(node.data?.createdAt.toString() ?? "N/A"),
                leading: node.icon,
              ),
            ));
  }
}

extension on ExplorableNode {
  Icon get icon {
    if (isRoot) return const Icon(Icons.data_object);

    if (this is FolderNode) {
      if (isExpanded) return const Icon(Icons.folder_open);
      return const Icon(Icons.folder);
    }

    if (this is FileNode) {
      final file = data as File;
      if (file.mimeType.startsWith("image")) return const Icon(Icons.image);
      if (file.mimeType.startsWith("video")) {
        return const Icon(Icons.video_file);
      }
    }

    return const Icon(Icons.insert_drive_file);
  }
}
