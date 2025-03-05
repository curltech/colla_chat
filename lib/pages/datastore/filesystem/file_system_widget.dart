import 'dart:io';

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_node.dart';
import 'package:colla_chat/pages/datastore/filesystem/file_system_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

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
  void _onTap(BuildContext context, FolderNode folderNode) {
    fileSystemController.currentNode.value = folderNode;
    indexWidgetProvider.push('file');
  }

  Widget _buildFolderButtonWidget(BuildContext context) {
    return OverflowBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            tooltip: AppLocalizations.t('New folder'),
            onPressed: () {
              _addFolder(context);
            },
            icon: Icon(
              Icons.add,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Delete folder'),
            onPressed: () async {
              _deleteFolder(context);
            },
            icon: Icon(
              Icons.remove,
              color: myself.primary,
            )),
        IconButton(
            tooltip: AppLocalizations.t('Rename folder name'),
            onPressed: () async {
              _renameFolder(context);
            },
            icon: Icon(
              Icons.drive_file_rename_outline_outlined,
              color: myself.primary,
            )),
      ],
    );
  }

  Future<void> _addFolder(BuildContext context) async {
    FolderNode? folderNode = fileSystemController.currentNode.value;
    if (folderNode == null) {
      return;
    }
    Folder? folder = folderNode.data;
    if (folder == null) {
      return;
    }
    String path = folder.directory.path;
    String? content = await DialogUtil.showTextFormField(
        context: context, title: 'New folder name');
    if (content != null) {
      String name = p.join(path, content);
      Directory directory = Directory(name);
      directory.createSync();
      folderNode.add(FolderNode(
          data: Folder(
              name: PathUtil.basename(directory.path), directory: directory)));
    }
  }

  Future<void> _deleteFolder(BuildContext context) async {
    FolderNode? folderNode = fileSystemController.currentNode.value;
    if (folderNode == null) {
      return;
    }
    Folder? folder = folderNode.data;
    if (folder == null) {
      return;
    }
    bool? confirm = await DialogUtil.confirm(
        context: context,
        content: 'Do you confirm delete folder:${folder.name}?');
    if (confirm != null && confirm) {
      Directory directory = folder.directory;
      folderNode.delete();
      directory.deleteSync(recursive: true);
    }
  }

  Future<void> _renameFolder(BuildContext context) async {
    Folder? folder = fileSystemController.currentNode.value?.data;
    if (folder == null) {
      return;
    }
    String path = folder.directory.path;
    String name = PathUtil.basename(path);
    String? content = await DialogUtil.showTextFormField(
        context: context, title: 'New folder name', content: name);
    if (content != null && content != name) {
      name = p.join(p.dirname(path), content);
      Directory directory = folder.directory.renameSync(name);
      folder.directory = directory;
    }
  }

  Widget _buildTreeViewWidget(BuildContext context) {
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
              selected = fileSystemController.currentNode.value == node;
            }
            TileData tileData = TileData(
              title: node.data?.name ?? "/",
              titleTail: node is FolderNode ? node.length.toString() : null,
              dense: true,
              prefix: node.icon,
              selected: selected,
              onTap: (int index, String label, {String? subtitle}) {
                _onTap(context, node as FolderNode);
                _onItemTap(node);
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
          _onItemTap(node as FolderNode);
        });
  }

  _onItemTap(FolderNode node) {
    if (node.length == 0) {
      try {
        fileSystemController.findDirectory(node);
      } catch (e) {
        DialogUtil.error(content: 'list directory failure:$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFolderButtonWidget(context),
        Expanded(child: _buildTreeViewWidget(context))
      ],
    );
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
