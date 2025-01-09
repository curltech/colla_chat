import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_node.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 数据存储管理功能主页面，带有路由回调函数
class FileSystemWidget extends StatelessWidget with TileDataMixin {
  FileSystemWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'file_system';

  @override
  IconData get iconData => Icons.explore;

  @override
  String get title => 'FileSystem';

  TreeViewController? treeViewController;

  @override
  Widget build(BuildContext context) {
    return TreeView.simpleTyped<Explorable, ExplorableNode>(
        tree: TreeNode.root(),
        showRootNode: true,
        expansionBehavior: ExpansionBehavior.scrollToLastChild,
        expansionIndicatorBuilder: (context, node) {
          return ChevronIndicator.rightDown(
            tree: node,
            alignment: Alignment.centerLeft,
            color: Colors.grey[700],
          );
        },
        indentation: Indentation(color: Colors.black),
        builder: (context, ExplorableNode node) => Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ListTile(
                title: Text(node.data?.name ?? "/"),
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
