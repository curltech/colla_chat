import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_system_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 文件管理功能主页面，带有路由回调函数
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

  /// 单击表示编辑属性
  void _onTap(BuildContext context, ExplorableNode node) {
    fileSystemController.currentNode.value = node;
    TreeNode? folderNode;
    if (node is FolderNode) {
      folderNode = node;
    }
    fileSystemController.current.value = folderNode?.data;
    indexWidgetProvider.push('file');
  }

  /// 长按表示进一步的操作
  Future<void> _onLongPress(BuildContext context, ExplorableNode node) async {
    fileSystemController.currentNode.value = node;
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

  _onPopAction(
      BuildContext context, ExplorableNode node, int index, String label,
      {String? value}) async {
    switch (label) {
      case 'New':
        // _add(node);
        break;
      case 'Delete':
        // _delete(node);
        break;
      case 'Edit':
        // _edit(node);
        break;
      case 'Query':
        // _query(node);
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return TreeView.simpleTyped<Explorable, ExplorableNode>(
        tree: fileSystemController.root,
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
          fileSystemController.treeViewController = controller;
        },
        builder: (context, ExplorableNode node) {
          return Obx(() {
            bool selected = false;
            if (node is FolderNode) {
              selected = fileSystemController.current.value == node.data;
            }
            TileData tileData = TileData(
              title: node.data?.name ?? "/",
              titleTail: node is FolderNode ? node.length.toString() : null,
              dense: true,
              prefix: node.icon,
              selected: selected,
              onTap: (int index, String label, {String? subtitle}) {
                _onTap(context, node);
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
          if (node.length == 0) {
            try {
              fileSystemController.findDirectory(node as FolderNode);
            } catch (e) {
              DialogUtil.error(content: 'list directory failure:$e');
            }
          }
        });
  }
}

extension on ExplorableNode {
  Icon get icon {
    if (isRoot) return const Icon(Icons.data_object);

    if (this is FolderNode) {
      if (isExpanded) {
        return Icon(
          Icons.folder_open,
          color: myself.primary,
        );
      }
      return Icon(
        Icons.folder,
        color: myself.primary,
      );
    }

    return Icon(
      Icons.insert_drive_file,
      color: myself.primary,
    );
  }
}
